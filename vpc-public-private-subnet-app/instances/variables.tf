variable "ec2_instance_type" {
    description = "EC2 instance type to launch"
}

variable "key_pair_name" {
  description = "Keypair to use to connect to EC2 Instances"
}

variable "instance_max_size" {
  description = "Instance max size"
}

variable "instance_min_size" {
  description = "Instance min size"
}