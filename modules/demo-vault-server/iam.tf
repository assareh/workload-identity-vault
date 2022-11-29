//--------------------------------------------------------------------
// Resources

## Vault Server IAM Config
resource "aws_iam_instance_profile" "vault-server" {
  name = "vault-server-instance-profile"
  role = aws_iam_role.vault-server.name
}

resource "aws_iam_role" "vault-server" {
  name               = "vault-server-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
}

resource "aws_iam_role_policy" "vault-server" {
  name   = "vault-server-role-policy"
  role   = aws_iam_role.vault-server.id
  policy = data.aws_iam_policy_document.vault-server.json
}

resource "aws_iam_role_policy_attachment" "vault-server" {
  role       = aws_iam_role.vault-server.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

//--------------------------------------------------------------------
// Data Sources

data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-server" {
  statement {
    sid       = "ConsulAutoJoin"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    sid    = "VaultAWSSecrets"
    effect = "Allow"
    actions = [
      "iam:AttachUserPolicy",
      "iam:CreateAccessKey",
      "iam:CreateUser",
      "iam:DeleteAccessKey",
      "iam:DeleteUser",
      "iam:DeleteUserPolicy",
      "iam:DetachUserPolicy",
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
      "iam:ListUserPolicies",
      "iam:PutUserPolicy",
      "iam:AddUserToGroup",
      "iam:RemoveUserFromGroup"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }
}

