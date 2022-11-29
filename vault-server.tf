module "vault" {
  source = "./modules/demo-vault-server"

  aws_region             = var.aws_region
  organization           = var.organization
  security_group_allowed = aws_security_group.tfc_agent.id
  subnet_id              = aws_subnet.tfc_agent.id
  vpc_id                 = aws_vpc.main.id
  workspace              = tfe_workspace.tfc-demo-workload-identity.name
}