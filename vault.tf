# example of how it could be configured, but have to do this in userdata because 
# provider attributes can't be dynamic in a single workspace

# provider "vault" {
#   # It is strongly recommended to configure this provider through the
#   # environment variables described above, so that each user can have
#   # separate credentials set in the environment.
#   #
#   # This will default to using $VAULT_ADDR
#   # But can be set explicitly
#   address = module.vault.vault_public_addr

#   auth_login_userpass {
#     username = "terraform"
#     password = module.vault.vault_password
#   }
# }

# resource "vault_aws_secret_backend" "aws" {
#   description = "The AWS secrets engine generates AWS access credentials dynamically based on IAM policies."
#   region      = var.aws_region

#   default_lease_ttl_seconds = 7200
#   max_lease_ttl_seconds     = 7200
# }

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
#          "ec2:Describe*"
#       ],
#       "Resource": "*"
#    }
#    ]
# }
# EOT
# }

# resource "vault_policy" "tfc-demo-plan-policy" {
#   name = "tfc-demo-plan-policy"

#   policy = <<EOT
# # Allow tokens to revoke themselves
# path "auth/token/revoke-self" {
#     capabilities = ["update"]
# }

# # Allow generate tfc demo plan role credentials
# path "aws/creds/tfc-demo-plan-role" {
#   capabilities = ["read"]
# }
# EOT
# }

# resource "vault_aws_secret_backend_role" "tfc-demo-apply-role" {
#   backend         = vault_aws_secret_backend.aws.path
#   name            = "tfc-demo-apply-role"
#   credential_type = "iam_user"

#   policy_document = <<EOT
# {
#    "Version": "2012-10-17",
#    "Statement": [{
#       "Effect": "Allow",
#       "Action": [
#          "ec2:*"
#       ],
#       "Resource": "*"
#    }
#    ]
# }
# EOT
# }

# resource "vault_policy" "tfc-demo-apply-policy" {
#   name = "tfc-demo-apply-policy"

#   policy = <<EOT
# # Allow tokens to revoke themselves
# path "auth/token/revoke-self" {
#     capabilities = ["update"]
# }

# # Allow generate tfc demo apply role credentials
# path "aws/creds/tfc-demo-apply-role" {
#   capabilities = ["read"]
# }
# EOT
# }

# resource "vault_jwt_auth_backend" "tfc-jwt" {
#   path               = "jwt"
#   oidc_discovery_url = "https://app.terraform.io"
#   bound_issuer       = "https://app.terraform.io"
# }

# resource "vault_jwt_auth_backend_role" "tfc-demo-plan-role" {
#   backend           = vault_jwt_auth_backend.tfc-jwt.path
#   role_name         = "tfc-demo-plan-role"
#   token_policies    = ["tfc-demo-plan-policy"]
#   token_ttl         = 7200
#   token_max_ttl     = 7200
#   bound_audiences   = ["vault.workload.identity"]
#   bound_claims_type = "glob"
#   bound_claims = {
#     sub = "organization:${var.organization}:workspace:${tfe_workspace.tfc-demo-workload-identity.name}:run_phase:plan"
#   }
#   user_claim = "terraform_full_workspace"
#   role_type  = "jwt"
# }

# resource "vault_jwt_auth_backend_role" "tfc-demo-apply-role" {
#   backend           = vault_jwt_auth_backend.tfc-jwt.path
#   role_name         = "tfc-demo-apply-role"
#   token_policies    = ["tfc-demo-apply-policy"]
#   token_ttl         = 7200
#   token_max_ttl     = 7200
#   bound_audiences   = ["vault.workload.identity"]
#   bound_claims_type = "glob"
#   bound_claims = {
#     sub = "organization:${var.organization}:workspace:${tfe_workspace.tfc-demo-workload-identity.name}:run_phase:apply"
#   }
#   user_claim = "terraform_full_workspace"
#   role_type  = "jwt"
# }
