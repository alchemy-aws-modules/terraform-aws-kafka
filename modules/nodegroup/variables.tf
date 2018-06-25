variable "custom_ami" {
  description = "Custom Linux AMI. Overrides AMI region mappings"
  default     = ""
}

variable "ami" {
  default = "CentOS-7-HVM"
}

variable "ami_region_map" {
  default = {
    "us-east-1" = {
      "AMZNLINUXHVM" = "ami-14c5486b"
      "CENTOS7HVM"   = "ami-d5bf2caa"
      "US1604HVM"    = "ami-5c66ea23"
    }
  }
}

variable "ami_name_map" {
  default = {
    "Amazon-Linux-HVM"            = "AMZNLINUXHVM"
    "CentOS-7-HVM"                = "CENTOS7HVM"
    "Ubuntu-Server-16.04-LTS-HVM" = "US1604HVM"
  }
}

variable "assign_public_ip" {
  description = "allocate a public ip address to each instance"
  default     = false
}

variable "instance_profile" {
  description = "IAM profile for the deployment"
}

variable "instance_type" {
  description = "Instance type"
  default     = "t2.medium"
}

variable "key_name" {
  description = "name of an existing EC2 Keypair"
}

variable "name" {
  description = "name of the node group"
}

variable "num_nodes" {
  default = 3
}

variable "region" {
  description = "the region we're launching in"
  default     = "us-east-1"
}

variable "root_volume_size" {
  description = "allocated EBS storage for boot disk"
  default     = 24
}

variable "security_groups" {
  description = "list of security groups for the members of the cluster"
  type        = "list"
}

variable "subnet_ids" {
  type = "list"
}

variable "tags" {
  description = "additional tags to apply to all resources"
  type        = "map"
}

variable "volume_size" {
  description = "Allocated EBS storage for each block device (in GiB; 4 devices per node)"
  default     = 24
}

variable "volume_type" {
  description = "EBS volume type"
  default     = ""
}

variable "eni_reference" {
  description = "Reference tag set on ENI available for use to node group"
}

variable "extra_userdata" {
  default     = ""
  description = "Extra user-data to add to the default built-in"
}

variable "extra_userdata_type" {
  default     = "text/cloud-config"
  description = "What format is extra_userdata in - eg 'text/cloud-config' or 'text/x-shellscript'"
}

variable "extra_userdata_merge" {
  default     = "list(append)+dict(recurse_array)+str()"
  description = "Control how cloud-init merges user-data sections"
}
