variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-west-2"
}

variable "vpc_name" {
  description = "The vpc name."
  default     = "web0"
}



# ubuntu-trusty-14.04 (x64)
variable "aws_amis" {
  type = "map"
  default = {
    "us-west-2" = "ami-082fd9a18128c9e8c"
  }
}

variable "availability_zones" {
  type    = "list"
  default     = ["us-west-2a", "us-west-2b"]
  description = "availability zone, use AWS CLI to find your "
}



variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "1"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "1"
}