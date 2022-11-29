output "info" {
  value = <<EOF

Vault Server IP (public): ${aws_instance.vault-server.public_ip}
Vault UI URL:             https://${aws_instance.vault-server.public_ip}:8200/ui

You can SSH into the Vault EC2 instance using private.key:
    ssh -i private.key ubuntu@${aws_instance.vault-server.public_ip}

EOF
}

output "vault_private_addr" {
  value = "https://${aws_instance.vault-server.private_ip}:8200"
}

output "vault_public_addr" {
  value = "https://${aws_instance.vault-server.public_ip}:8200"
}

# output "vault_password" {
#   value = random_password.password.result
# }

output "ssh_private_key" {
  value = tls_private_key.main.private_key_pem
}