provider "tfe" {
}

resource "tfe_agent_pool" "workload-identity" {
  name         = "workload-identity"
  organization = var.organization
}

resource "tfe_agent_token" "workload-identity-agent-token" {
  agent_pool_id = tfe_agent_pool.workload-identity.id
  description   = "terraform"
}

resource "tfe_workspace" "tfc-demo-workload-identity" {
  name           = var.demo_workspace_name
  organization   = var.organization
  queue_all_runs = false
  execution_mode = "agent"
  agent_pool_id  = tfe_agent_pool.workload-identity.id

  vcs_repo {
    identifier     = var.vcs_identifier
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_variable" "workload-identity-audience" {
  key          = "TFC_WORKLOAD_IDENTITY_AUDIENCE"
  value        = "vault.workload.identity"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "Sets the audience of the identity token. Needed to enable workload identity functionality."
}

resource "tfe_variable" "vault_addr" {
  key          = "VAULT_ADDR"
  value        = var.vault_addr
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The address of your Vault instance. This is needed for when the instance is reached out to for JWT authentication in pre hook scripts."
}

resource "tfe_variable" "workload-identity-plan-role" {
  key          = "TFC_VAULT_PLAN_ROLE"
  value        = "tfc-demo-plan-role"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The name of the role that should be assumed when generating the Vault token for a plan."
}

resource "tfe_variable" "workload-identity-apply-role" {
  key          = "TFC_VAULT_APPLY_ROLE"
  value        = "tfc-demo-apply-role"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The name of the role that should be assumed when generating the Vault token for a apply."
}

provider "docker" {
  host = var.docker_host
}

# resource "docker_registry_image" "tfc-agent-custom" {
#   name = "assareh/tfc-agent"

#   build {
#     context = "${path.cwd}/docker"
#   }
# }

resource "docker_image" "tfc-agent-custom" {
  name = "assareh/tfc-agent"
}

resource "docker_container" "tfc-agent" {
  image = docker_image.tfc-agent-custom.image_id
  name  = "tfc-agent-custom"

  env = [
    "TFC_AGENT_TOKEN=${tfe_agent_token.workload-identity-agent-token.token}",
    "TFC_AGENT_NAME=local-demo"
  ]
}

provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

resource "vault_aws_secret_backend" "aws" {
  description = "The AWS secrets engine generates AWS access credentials dynamically based on IAM policies."
  region      = var.aws_region

  default_lease_ttl_seconds = 7200
  max_lease_ttl_seconds     = 7200
}

# resource "vault_aws_secret_backend_role" "tfc-demo-plan-role" {
#   backend         = vault_aws_secret_backend.aws.path
#   name            = "tfc-demo-plan-role"
#   credential_type = "iam_user"

#   policy_document = <<EOT
# {
#    "Version": "2012-10-17",
#    "Statement": [{
#       "Effect": "Allow",
#       "Action": [
#          "ec2:DescribeInstances", 
#          "ec2:DescribeImages",
#          "ec2:DescribeTags", 
#          "ec2:DescribeSnapshots"
#       ],
#       "Resource": "*"
#    }
#    ]
# }
# EOT
# }

resource "vault_jwt_auth_backend" "tfc-jwt" {
  path               = "jwt"
  oidc_discovery_url = "https://app.terraform.io"
  bound_issuer       = "https://app.terraform.io"
}

resource "vault_jwt_auth_backend_role" "tfc-demo-plan-role" {
  backend           = vault_jwt_auth_backend.tfc-jwt.path
  role_name         = "tfc-demo-plan-role"
  token_policies    = ["tfc-demo-plan-policy"]
  token_ttl         = 7200
  token_max_ttl     = 7200
  bound_audiences   = ["vault.workload.identity"]
  bound_claims_type = "glob"
  bound_claims = {
    sub = "organization:${var.organization}:workspace:${tfe_workspace.tfc-demo-workload-identity.name}:run_phase:plan"
  }
  user_claim = "terraform_full_workspace"
  role_type  = "jwt"
}

resource "vault_policy" "tfc-demo-plan-policy" {
  name = "tfc-demo-plan-policy"

  policy = <<EOT
# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}

# Allow generate tfc demo plan role credentials
path "aws/creds/tfc-demo-plan-role" {
  capabilities = ["read"]
}
EOT
}