variable "name" {
  default = "confluent"
}

variable "ami" {
  description = "id of Linux AMI to launch with"
  default     = "CentOS-7-HVM"
}

variable "custom_ami" {
  description = "Custom Linux AMI. Overrides AMI region mappings"
  default     = ""
}

variable "assign_public_ip" {
  description = "Allocate a public IP address to each instance"
  default     = false
}

variable "root_volume_size" {
  description = "Allocated EBS storage for root volume"
  default     = 24
}

variable "broker_node_instance_type" {
  description = "instance type for Kafka Brokers"
  default     = "t2.medium"
}

variable "broker_node_storage" {
  default = 24
}

variable "broker_node_storage_type" {
  description = "EBS volume type. sc1 and st1 volumes must be at least 500 GiB"
  default     = "st1"
}

variable "key_name" {}

variable "num_brokers" {
  default = 3
}

variable "num_zookeepers" {
  default = 3
}

variable "private_zone_id" {
  description = "The ID of the hosted zone for the private DNS record(s)."
  default     = ""
  type        = "string"
}

variable "ttl" {
  description = "The TTL (in seconds) for the DNS record(s)."
  default     = "600"
  type        = "string"
}

variable "region" {
  description = "the region to launch in"
  default     = "us-east-1"
}

variable "remote_access_cidr" {
  description = "Allowed CIDR block for external access to cluster nodes"
  type        = "list"
  default     = []
}

variable "ssh_access_cidr" {
  description = "Allowed CIDR block for SSH access to cluster nodes"
  type        = "list"
  default     = []
}

variable "subnet_ids" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

variable "zookeeper_node_instance_type" {
  default = "t2.medium"
}

variable "zookeeper_node_storage" {
  default = 24
}

variable "tags" {
  description = "tags to apply to all resources"
  type        = "map"
}
