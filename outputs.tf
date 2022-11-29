output "demo_workspace" {
  value = "https://app.terraform.io/app/${var.organization}/workspaces/${var.demo_workspace_name}/"
}

output "info" {
  value = <<EOT
${module.vault.info}You can view the bootstrap logs with:
    tail /var/log/tf-user-data.log

You can view the Vault audit logs with:
    sudo tail -f /var/log/vault_audit.log | jq
EOT
}

output "ssh_private_key" {
  value = nonsensitive(module.vault.ssh_private_key)
}
