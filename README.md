This repo:
* creates a demo Vault instance with the AWS secrets engine enabled
* deploys an agent to be used by workload identity
* creates a demo workspace enabled with workload identity

Requires:
* TFE_TOKEN for `tfe` provider auth
* fork the hashicat-aws repo
* see tfvars

The agent can be run anywhere that has access to Vault. It does not need to be in the cloud with IAM because Terraform Cloud Workload Identity (JWT tokens) are used for trust. 

For simplicity and demo convenience I am making Vault public, though TLS in use
but in practice publicly reachable Vault is not required.
Terraform cloud agent could be used for provisioning into private networks.

TODO
stable ip
container registry