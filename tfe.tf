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
  value        = module.vault.vault_private_addr
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

resource "tfe_variable" "prefix" {
  key          = "prefix"
  value        = "demo"
  category     = "terraform"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "This prefix will be included in the name of most resources."
}

resource "tfe_variable" "region" {
  key          = "region"
  value        = var.aws_region
  category     = "terraform"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The region where the resources are created."
}