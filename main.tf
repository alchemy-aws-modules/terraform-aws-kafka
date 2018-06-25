locals {
  kafka_addrs     = "${split(",", replace(replace(replace(format("%s", aws_network_interface.kafka.*.private_ips), "/[^\\s\\d\\.]/", ""), "/(\\d)\\s+/", "$1,"), "/\\s+/", ""))}"
  zookeeper_addrs = "${split(",", replace(replace(replace(format("%s", aws_network_interface.zookeeper.*.private_ips), "/[^\\s\\d\\.]/", ""), "/(\\d)\\s+/", "$1,"), "/\\s+/", ""))}"
}

// IAM
resource "aws_iam_role" "instance" {
  name = "${var.name}-confluent-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-confluent-profile"
  role = "${aws_iam_role.instance.name}"
}

resource "aws_iam_role_policy" "eni" {
  name = "${var.name}-confluent-eni"
  role = "${aws_iam_role.instance.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeNetworkInterfaceAttribute",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

// Security Groups
resource "aws_security_group" "kafka" {
  name        = "${var.name}-kafka-sg"
  description = "Kafka Brokers Security Group"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(var.tags, map(
    "Name", "${var.name}-kafka-sg"
  ))}"
}

resource "aws_security_group_rule" "kafka_ingress_replication" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.kafka.id}"
  source_security_group_id = "${aws_security_group.kafka.id}"
}

resource "aws_security_group_rule" "kafka_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.kafka.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "kafka_ssh" {
  count             = "${length(var.ssh_access_cidr) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kafka.id}"
  cidr_blocks       = ["${var.ssh_access_cidr}"]
}

resource "aws_security_group_rule" "kafka_remote_ingress" {
  count             = "${length(var.remote_access_cidr) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 9092
  to_port           = 9092
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kafka.id}"
  cidr_blocks       = ["${var.remote_access_cidr}"]
}

resource "aws_security_group" "zookeeper" {
  name        = "${var.name}-zookeeper-sg"
  description = "Zookeeper Security Group"
  vpc_id      = "${var.vpc_id}"

  tags = "${merge(var.tags, map(
    "Name", "${var.name}-zookeeper-sg"
  ))}"
}

resource "aws_security_group_rule" "zookeeper_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.zookeeper.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "zookeeper_ingress_2888" {
  type                     = "ingress"
  from_port                = 2888
  to_port                  = 2888
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zookeeper.id}"
  source_security_group_id = "${aws_security_group.zookeeper.id}"
}

resource "aws_security_group_rule" "zookeeper_ingress_3888" {
  type                     = "ingress"
  from_port                = 3888
  to_port                  = 3888
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zookeeper.id}"
  source_security_group_id = "${aws_security_group.zookeeper.id}"
}

resource "aws_security_group_rule" "zookeeper_broker_ingress" {
  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.zookeeper.id}"
  source_security_group_id = "${aws_security_group.kafka.id}"
}

resource "aws_security_group_rule" "zookeeper_ssh" {
  count             = "${length(var.ssh_access_cidr) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.zookeeper.id}"
  cidr_blocks       = ["${var.ssh_access_cidr}"]
}

resource "aws_security_group_rule" "zookeeper_remote_ingress" {
  count             = "${length(var.remote_access_cidr) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = 2181
  to_port           = 2181
  protocol          = "tcp"
  security_group_id = "${aws_security_group.zookeeper.id}"
  cidr_blocks       = ["${var.remote_access_cidr}"]
}

// ENI
resource "aws_network_interface" "kafka" {
  count             = "${var.num_brokers}"
  subnet_id         = "${element(var.subnet_ids, count.index)}"
  security_groups   = ["${aws_security_group.kafka.id}"]
  source_dest_check = false

  tags = "${merge(var.tags, map(
    "Reference", "${var.name}-kafka-eni"
  ))}"
}

resource "aws_network_interface" "zookeeper" {
  count             = "${var.num_zookeepers}"
  subnet_id         = "${element(var.subnet_ids, count.index)}"
  security_groups   = ["${aws_security_group.zookeeper.id}"]
  source_dest_check = false

  tags = "${merge(var.tags, map(
    "Reference", "${var.name}-zookeeper-eni"
  ))}"
}

resource "aws_route53_record" "private_kafka" {
  count   = "${var.private_zone_id != "" ? var.num_brokers : 0}"
  name    = "${var.name}-kafka-${format("%02d", count.index + 1)}"
  records = ["${element(local.kafka_addrs, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.private_zone_id}"
}

resource "aws_route53_record" "private_zookeeper" {
  count   = "${var.private_zone_id != "" ? var.num_zookeepers : 0}"
  name    = "${var.name}-zookeeper-${format("%02d", count.index + 1)}"
  records = ["${element(local.zookeeper_addrs, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.private_zone_id}"
}

data "template_file" "kafka" {
  template = "${file("${path.module}/modules/nodegroup/templates/cloud-config/kafka-init.tpl.yml")}"

  vars {
    zookeeper_connect = "${join(",", formatlist("%s:%s", local.zookeeper_addrs, "2181"))}"
  }
}

// Instances
module "kafka" {
  source           = "./modules/nodegroup"
  ami              = "${var.ami}"
  custom_ami       = "${var.custom_ami}"
  assign_public_ip = "${var.assign_public_ip}"
  instance_profile = "${aws_iam_instance_profile.instance.name}"
  eni_reference    = "${var.name}-kafka-eni"

  extra_userdata = "${data.template_file.kafka.rendered}"

  /* instance_role    = "${aws_iam_role.instance.id}" */
  key_name         = "${var.key_name}"
  name             = "${var.name}-kafka"
  num_nodes        = "${var.num_brokers}"
  region           = "${var.region}"
  root_volume_size = "${var.root_volume_size}"
  security_groups  = ["${aws_security_group.kafka.id}"]
  subnet_ids       = ["${var.subnet_ids}"]
  tags             = "${var.tags}"

  tags = "${merge(var.tags, map(
    "Name", "${var.name}-kafka"
  ))}"
}

data "template_file" "zookeeper_addr" {
  count    = "${var.num_zookeepers}"
  template = "server.$${index}=$${address}:2888:3888"

  vars {
    address = "${element(local.zookeeper_addrs, count.index)}"
    index   = "${count.index + 1}"
  }
}

data "template_file" "zookeeper" {
  template = "${file("${path.module}/modules/nodegroup/templates/cloud-config/zookeeper-init.tpl.yml")}"

  vars {
    zookeeper_servers = "${indent(6, join("\n", data.template_file.zookeeper_addr.*.rendered))}"
  }
}

module "zookeeper" {
  source           = "./modules/nodegroup"
  ami              = "${var.ami}"
  custom_ami       = "${var.custom_ami}"
  assign_public_ip = "${var.assign_public_ip}"
  instance_profile = "${aws_iam_instance_profile.instance.id}"
  eni_reference    = "${var.name}-zookeeper-eni"
  extra_userdata   = "${data.template_file.zookeeper.rendered}"

  /* instance_role    = "${aws_iam_role.instance.id}" */
  key_name         = "${var.key_name}"
  name             = "${var.name}-zookeeper"
  num_nodes        = "${var.num_zookeepers}"
  region           = "${var.region}"
  root_volume_size = "${var.root_volume_size}"
  security_groups  = ["${aws_security_group.zookeeper.id}"]
  subnet_ids       = ["${var.subnet_ids}"]

  tags = "${merge(var.tags, map(
    "Name", "${var.name}-zookeeper"
  ))}"
}
