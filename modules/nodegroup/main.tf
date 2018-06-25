// This is needed so we can interpolate var.tags into aws_autoscaling_group.tags,
// which expectes a list instead of a map. See: 
data "null_data_source" "tags" {
  count = "${length(keys(var.tags))}"

  inputs = {
    key                 = "${element(keys(var.tags), count.index)}"
    value               = "${element(values(var.tags), count.index)}"
    propagate_at_launch = true
  }
}

data "template_file" "node" {
  template = "${file("${path.module}/templates/cloud-config/init.tpl.yml")}"

  vars {
    eni_reference = "${var.eni_reference}"
    region        = "${var.region}"
  }
}

data "template_cloudinit_config" "node" {
  gzip          = false
  base64_encode = true

  part {
    content = "${data.template_file.node.rendered}"
  }

  part {
    content_type = "${var.extra_userdata_type}"
    content      = "${var.extra_userdata}"
    merge_type   = "${var.extra_userdata_merge}"
  }
}

resource "aws_autoscaling_group" "nodes" {
  name_prefix          = "${var.name}"
  desired_capacity     = "${var.num_nodes}"
  max_size             = "${var.num_nodes}"
  min_size             = 0
  launch_configuration = "${aws_launch_configuration.nodes.name}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  tags                 = ["${data.null_data_source.tags.*.outputs}"]
}

resource "aws_launch_configuration" "nodes" {
  associate_public_ip_address = "${var.assign_public_ip}"
  key_name                    = "${var.key_name}"
  image_id                    = "${length(var.custom_ami) > 0 ? var.custom_ami : lookup(var.ami_region_map[var.region], lookup(var.ami_name_map, var.ami))}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${var.security_groups}"]
  iam_instance_profile        = "${var.instance_profile}"

  /* user_data = "${data.template_file.node.rendered}" */
  user_data = "${data.template_cloudinit_config.node.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}
