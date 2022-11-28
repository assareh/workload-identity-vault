#/bin/bash

doormat login -f
eval "$( doormat aws export --account 828591310358 )"
vault server -dev -dev-root-token-id=root &
vault status
VAULT_TOKEN=root vault audit enable -local=true file file_path=/tmp/vault_audit.log