# AWS region and AZs in which to deploy
variable "aws_region" {
  default = "us-west-2"
}

# Instance size
variable "instance_type" {
  default = "t2.micro"
}

variable "organization" {
  type = string
}

variable "security_group_allowed" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "workspace" {
  type = string
}