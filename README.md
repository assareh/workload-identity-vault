This repo:
* creates a demo Vault instance with the AWS secrets engine enabled
* deploys a terraform cloud agent to be used by terraform cloud workload identity
* creates a demo terraform cloud workspace with workload identity enabled

Requires:
* AWS credentials
* TFE_TOKEN for `tfe` provider auth
* fork the [hashicat-aws](https://github.com/hashicorp/hashicat-aws) repo to your github
* provided values for required [tfvars](./variables.tf)

In this example the tfc-agent can be run anywhere that has access to Vault. As opposed to [this tfc-agent-ecs example](https://github.com/assareh/tfc-agent/tree/master/tfc-agent-ecs), with workload identity the agent does not need to be run in the cloud with IAM because Terraform Cloud Workload Identity (JWT tokens) are used to establish trust. 

TODO
* stable ip
* container registry