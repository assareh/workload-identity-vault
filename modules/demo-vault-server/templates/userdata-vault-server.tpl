#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

##--------------------------------------------------------------------
## Variables

# Get Private IP address
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

AWS_REGION="${tpl_aws_region}"
KMS_KEY="${tpl_kms_key}"

##--------------------------------------------------------------------
## Install Base Prerequisites

logger "Setting timezone to UTC"
sudo timedatectl set-timezone UTC

logger "Performing updates and installing prerequisites"
sudo apt-get -qq -y update
sudo apt-get install -qq -y wget unzip ntp jq
sudo systemctl start ntp.service
sudo systemctl enable ntp.service
logger "Disable reverse dns lookup in SSH"
sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
sudo service ssh restart

##--------------------------------------------------------------------
## Install Vault

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y vault

logger "/usr/bin/vault --version: $(/usr/bin/vault --version)"

logger "Configuring Vault"
sudo tee /etc/vault.d/vault.hcl <<EOF
storage "file" {
    path = "/opt/vault/data"
}

listener "tcp" {
  address     = "$${PRIVATE_IP}:8200"

  tls_cert_file            = "/opt/vault/tls/tls.crt"
  tls_key_file             = "/opt/vault/tls/tls.key"
  tls_disable_client_certs = true
}

seal "awskms" {
  region = "$${AWS_REGION}"
  kms_key_id = "$${KMS_KEY}"
}

ui=true
EOF

sudo chown -R vault:vault /etc/vault.d 
sudo chmod -R 0644 /etc/vault.d/*

sudo tee -a /etc/environment <<EOF
export VAULT_ADDR=https://$${PRIVATE_IP}:8200
export VAULT_SKIP_VERIFY=true
EOF

source /etc/environment

logger "Granting mlock syscall to vault binary"
sudo setcap cap_ipc_lock=+ep /usr/bin/vault

sudo systemctl enable vault
sudo systemctl start vault

vault status
# Wait until vault status serves the request and responds that it is sealed
while [[ $? -ne 2 ]]; do sleep 1 && vault status; done

##--------------------------------------------------------------------
## Configure Vault
##--------------------------------------------------------------------

# NOT SUITABLE FOR PRODUCTION USE
export VAULT_TOKEN="$(vault operator init -format json | jq -r '.root_token')"
sudo cat >> /etc/environment <<EOF
export VAULT_TOKEN=$${VAULT_TOKEN}
EOF

sudo touch /var/log/vault_audit.log
sudo chown vault:vault /var/log/vault_audit.log
vault audit enable file file_path=/var/log/vault_audit.log

vault policy write admin-policy - <<EOF
path "/*" {
  capabilities = ["read", "list"]
}

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage auth methods in nested namespaces
# This needs to be validated
path "+/auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create tokens in nested namespaces
# This needs to be validated
path "+/auth/token/create"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create and manage ACL policies via CLI
path "identity/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create and manage namespaces
path "sys/namespaces/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage Namespaces - came from vaultadmin.hcl
path "/sys/namespaces*" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

# List audit backends
path "/sys/audit" {
  capabilities = ["read","list"]
}

# Create an audit backend. Operators are not allowed to remove them.
path "/sys/audit/*" {
  capabilities = ["create","read","list","sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# CORS configuration
path "/sys/config/cors" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

# Start root token generation
path "/sys/generate-root/attempt" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

# Configure License
path "/sys/license" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

# Get Storage Key Status
path "/sys/key-status" {
  capabilities = ["read"]
}

# Initialize Vault
path "/sys/init" {
  capabilities = ["read", "update", "create"]
}

# Get Cluster Leader
path "/sys/leader" {
  capabilities = ["read"]
}

# List Leases
path "/sys/leases" {
  capabilities = ["read", "list", "update", "sudo"]
}

# List Leases in nested namespaces
# This needs to be validated
path "+/sys/leases/"
{
  capabilities = ["read", "list", "update", "sudo"]
}

# Manage Leases
path "/sys/leases/*" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

# Manage Leases in nested namespaces
# This needs to be validated
path "+/sys/leases/*" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

# To list policies
path "sys/policy"
{
  capabilities = ["read"]
}

# To manage policies
path "sys/policy/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies - from vaultadmin.hcl
path "/sys/policies*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

# Create and manage policies via API
# These policy blocks allow for newer (>0.9) policy management.
path "sys/policies/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Create and manage ACL policies via API
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create and manage Sentinel EGP policies via API
path "sys/policies/egp/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create and manage Sentinel RGP policies via API
path "sys/policies/rgp/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Capabilities
path "sys/capabilities"
{
  capabilities = ["create", "update"]
}

# To perform Step 4
path "sys/capabilities-self"
{
  capabilities = ["create", "update"]
}

# Manage Mounts - from vaultadmin.hcl
path "/sys/mounts*" {
  capabilities = ["read", "list", "create", "update", "delete"]
}

# Manage secret engines broadly across Vault
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secret engines
path "sys/mounts"
{
  capabilities = ["read"]
}

# Read health checks
# I don't believe this is necessary since this endpoint is unauthenticated
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Admin Control groups
path "sys/config/control-group"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/internal/ui/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

# vault auth enable userpass
# vault write auth/userpass/users/terraform \
#     password="{tpl_vault_password}" \
#     policies=admin

vault secrets enable -default-lease-ttl=2h -max-lease-ttl=2h aws 
vault write aws/roles/tfc-demo-plan-role \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:Describe*"],
      "Resource": ["*"]
    }
  ]
}
EOF

vault policy write tfc-demo-plan-policy - <<EOF
# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}

# Allow generate tfc demo plan role credentials
path "aws/creds/tfc-demo-plan-role" {
  capabilities = ["read"]
}
EOF

vault write aws/roles/tfc-demo-apply-role \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    }
  ]
}
EOF

vault policy write tfc-demo-apply-policy - <<EOF
# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}

# Allow generate tfc demo apply role credentials
path "aws/creds/tfc-demo-apply-role" {
  capabilities = ["read"]
}
EOF

vault auth enable jwt
vault write auth/jwt/config \
    oidc_discovery_url="https://app.terraform.io" \
    bound_issuer="https://app.terraform.io"

cat >> plan_payload.json <<EOF
{
  "policies": ["tfc-demo-plan-policy"],
  "token_ttl": "7200",
  "token_max_ttl": "7200",
  "bound_audiences": ["vault.workload.identity"],
  "bound_claims_type": "glob",
  "bound_claims": {
    "sub": "organization:${tpl_organization}:workspace:${tpl_workspace}:run_phase:plan"
  },
  "user_claim": "terraform_full_workspace",
  "role_type": "jwt"
}
EOF

vault write auth/jwt/role/tfc-demo-plan-role @plan_payload.json

cat >> apply_payload.json <<EOF
{
  "policies": ["tfc-demo-apply-policy"],
  "token_ttl": "7200",
  "token_max_ttl": "7200",
  "bound_audiences": ["vault.workload.identity"],
  "bound_claims_type": "glob",
  "bound_claims": {
    "sub": "organization:${tpl_organization}:workspace:${tpl_workspace}:run_phase:apply"
  },
  "user_claim": "terraform_full_workspace",
  "role_type": "jwt"
}
EOF

vault write auth/jwt/role/tfc-demo-apply-role @apply_payload.json

logger "Complete"

# There is a remote-exec provisioner in terraform watching for this file
touch /tmp/user-data-completed
