variable "aws_region" {
  description = "The region where the resources are created."
  default     = "us-west-2"
}

variable "demo_workspace_name" {
  description = "What the demo workspace will be named"
  default     = "demo-workload-identity"
}

variable "oauth_token_id" {
  description = "The VCS Connection (OAuth Connection + Token) to use"
}

variable "organization" {
  description = "Terraform Cloud organization name"
}

variable "vcs_identifier" {
  description = "VCS identifier of demo app for demo workspace"
}

// OPTIONAL Tags
variable "ttl" {
  description = "OPTIONAL for Cloud Custodian; value of ttl tag on cloud resources"
  default     = "1"
}

// OPTIONAL Tags
locals {
  common_tags = {
    owner              = "your-name-here"
    se-region          = "your-region-here"
    purpose            = "Default state is dormant with no active resources. Runs a Terraform Cloud Agent when a run is queued."
    ttl                = var.ttl # hours
    terraform          = "true"  # true/false
    hc-internet-facing = "false" # true/false
  }
}

variable "ip_cidr_vpc" {
  description = "IP CIDR for VPC"
  default     = "172.31.0.0/16"
}

variable "ip_cidr_agent_subnet" {
  description = "IP CIDR for tfc-agent subnet"
  default     = "172.31.16.0/24"
}

variable "task_cpu" {
  description = "The total number of cpu units used by the task."
  default     = 4096
}

variable "task_mem" {
  description = "The total amount (in MiB) of memory used by the task."
  default     = 8192
}

variable "task_def_cpu" {
  description = "The number of cpu units used by the task at the container definition level."
  default     = 1024
}

variable "task_def_mem" {
  description = "The amount (in MiB) of memory used by the task at the container definition level."
  default     = 2048
}

variable "desired_count" {
  description = "Desired count of tfc-agents to run. Suggested 2 * run concurrency. Default TFCB concurrency is 2. May want to set this lower as desired if using lamdba autoscaling."
  default     = 2
}