//--------------------------------------------------------------------
// Resources

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault-kms-unseal-key"
  target_key_id = aws_kms_key.vault.key_id
}
