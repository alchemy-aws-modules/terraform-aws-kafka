Heavily Inspired by: https://github.com/aws-quickstart/quickstart-confluent-kafka

# Motivation
Bringing a reliable Kafka option to Terraform deployments

# Usage
```
module "confluent_kafka" {
  source                       = "github.com/alchemy-aws-modules/terraform-aws-kafka"
  broker_node_instance_type    = "t2.small"
  key_name                     = "${var.key_name}"
  custom_ami                   = "${data.aws_ami.node.id}"
  vpc_id                       = "${module.vpc.vpc_id}"
  num_brokers                  = 3
  num_zookeepers               = 3
  subnet_ids                   = ["${module.vpc.private_subnets}"]
  private_zone_id              = "${data.aws_route53_zone.private.zone_id}"
  zookeeper_node_instance_type = "t2.small"
  ssh_access_cidr              = ["0.0.0.0/0"]
  remote_access_cidr           = ["0.0.0.0/0"]

  tags = {
    Terraform = "true"
  }
}
```
