module "vault" {
  source = "github.com/assareh/vault-lambda-extension//quick-start/terraform"

  aws_region   = var.aws_region
  subnet_id    = aws_subnet.tfc_agent.id
  vpc_id       = aws_vpc.main.id
  organization = var.organization
  workspace    = tfe_workspace.tfc-demo-workload-identity.name
}
