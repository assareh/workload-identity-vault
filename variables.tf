# variable "aws_access_key_id" {
#   description = "Used in demo to configure Vault AWS secrets engine"
# }

# variable "aws_secret_key" {
#   description = "Used in demo to configure Vault AWS secrets engine"
# }

variable "aws_region" {
  description = "The region where the resources are created."
  default     = "us-west-2"
}

variable "demo_workspace_name" {
  description = "What the demo workspace will be named"
  default     = "demo-workload-identity"
}

variable "docker_host" {
  description = "Docker host address"
  default     = "unix:///var/run/docker.sock"
}

variable "oauth_token_id" {
  description = "The VCS Connection (OAuth Connection + Token) to use"
}

variable "organization" {
  description = "Terraform Cloud organization name"
}

variable "vault_addr" {
  description = "Vault address"
  default     = "http://docker.for.mac.host.internal:8200"
}

variable "vcs_identifier" {
  description = "VCS identifier of demo app for demo workspace"
  default     = "assareh/terraform-aws-ec2-instance"
}