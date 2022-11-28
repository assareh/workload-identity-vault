This repo:
* configures Vault for workload identity
~~* configures Vault for AWS secrets engine~~
* builds and deploys an agent to be used by workload identity
* creates a demo workspace enabled with workload identity

Requires:
* AWS Secrets engine in Vault set up per below
* VAULT_ADDR = 'http://docker.for.mac.host.internal:8200'
* VAULT_TOKEN
* TFE_TOKEN

How to:
1. Open a shell and log in to Doormat, following [these instructions](https://github.com/hashicorp/secops-docs/blob/272f19195e44379c31c1487242677f07bea38d7c/docs/service_user/demo_user/aws_vault_doormat.md).
2. Start Vault in that shell.
3. Apply the terraform code.
4. Create the aws role with the below:
```
vault write aws/roles/tfc-demo-plan-role \
    credential_type=iam_user \
    iam_tags="vault-demo=${HASHICORP_EMAIL}" \
    permissions_boundary_arn="${AWS_PERMISSION_BOUNDARY_ARN}" \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:DescribeRegions"],
      "Resource": ["*"]
    }
  ]
}
EOF
```

The agent can be run anywhere that has access to Vault. It does not need to be in the cloud with IAM because Terraform Cloud Workload Identity (JWT tokens) are used for trust. 

for now need to run `socat TCP-LISTEN:2376,reuseaddr,fork,bind=127.0.0.1 UNIX-CLIENT:/var/run/docker.sock` to make Docker for Mac listen on TCP port 2376
* but can likely fix this by running outer agent with docker socket mounted
or do this in another environment - aws perhaps - back to fargate 

HCP or AWS EC2 for Vault server - instruqt creds maybe
fargate for agents - they just need access to vault 
docker push my image up to public web

https://developer.hashicorp.com/terraform/cloud-docs/agents/hooks
