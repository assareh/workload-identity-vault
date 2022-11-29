provider "tfe" {
}

resource "tfe_agent_pool" "workload-identity" {
  name         = "workload-identity"
  organization = var.organization
}

resource "tfe_agent_token" "workload-identity-agent-token" {
  agent_pool_id = tfe_agent_pool.workload-identity.id
  description   = "terraform"
}

resource "tfe_workspace" "tfc-demo-workload-identity" {
  name           = var.demo_workspace_name
  organization   = var.organization
  queue_all_runs = false
  execution_mode = "agent"
  agent_pool_id  = tfe_agent_pool.workload-identity.id

  vcs_repo {
    identifier     = var.vcs_identifier
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_variable" "workload-identity-audience" {
  key          = "TFC_WORKLOAD_IDENTITY_AUDIENCE"
  value        = "vault.workload.identity"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "Sets the audience of the identity token. Needed to enable workload identity functionality."
}

resource "tfe_variable" "vault_addr" {
  key          = "VAULT_ADDR"
  value        = module.vault.vault_addr
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The address of your Vault instance. This is needed for when the instance is reached out to for JWT authentication in pre hook scripts."
}

resource "tfe_variable" "workload-identity-plan-role" {
  key          = "TFC_VAULT_PLAN_ROLE"
  value        = "tfc-demo-plan-role"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The name of the role that should be assumed when generating the Vault token for a plan."
}

resource "tfe_variable" "workload-identity-apply-role" {
  key          = "TFC_VAULT_APPLY_ROLE"
  value        = "tfc-demo-apply-role"
  category     = "env"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The name of the role that should be assumed when generating the Vault token for a apply."
}

resource "tfe_variable" "prefix" {
  key          = "prefix"
  value        = "demo"
  category     = "terraform"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "This prefix will be included in the name of most resources."
}

resource "tfe_variable" "region" {
  key          = "region"
  value        = var.aws_region
  category     = "terraform"
  workspace_id = tfe_workspace.tfc-demo-workload-identity.id
  description  = "The region where the resources are created."
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "main" {
  name                 = "tfc-agent-custom"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "tfc_agent" {
  name = "tfc-agent-cluster"
}

resource "aws_ecs_service" "tfc_agent" {
  name            = "tfc-agent-service"
  cluster         = aws_ecs_cluster.tfc_agent.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.tfc_agent.arn
  desired_count   = var.desired_count
  network_configuration {
    security_groups  = [aws_security_group.tfc_agent.id]
    subnets          = [aws_subnet.tfc_agent.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "tfc_agent" {
  family                   = "tfc-agent-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.agent_init.arn
  task_role_arn            = aws_iam_role.agent.arn
  cpu                      = var.task_cpu
  memory                   = var.task_mem
  container_definitions = jsonencode(
    [
      {
        name : "tfc-agent"
        image : "assareh/tfc-agent:latest"
        essential : true
        cpu : var.task_def_cpu
        memory : var.task_def_mem
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-create-group : "true",
            awslogs-group : "awslogs-tfc-agent"
            awslogs-region : var.aws_region
            awslogs-stream-prefix : "awslogs-tfc-agent"
          }
        }
        environment = [
          {
            name  = "TFC_AGENT_SINGLE",
            value = "true"
          },
          {
            name  = "TFC_AGENT_NAME",
            value = "ECS_Fargate"
          }
        ]
        secrets = [
          {
            name      = "TFC_AGENT_TOKEN",
            valueFrom = aws_ssm_parameter.agent_token.arn
          }
        ]
      }
    ]
  )
}

resource "aws_ssm_parameter" "agent_token" {
  name        = "tfc-agent-token"
  description = "Terraform Cloud agent token"
  type        = "SecureString"
  value       = tfe_agent_token.workload-identity-agent-token.token
}

# task execution role for agent init
resource "aws_iam_role" "agent_init" {
  name               = "tfc-agent-task-init-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy_definition.json
}

resource "aws_iam_role_policy" "agent_init_policy" {
  role   = aws_iam_role.agent_init.name
  name   = "AccessSSMParameterforAgentToken"
  policy = data.aws_iam_policy_document.agent_init_policy.json
}

resource "aws_iam_role_policy_attachment" "agent_init_policy" {
  role       = aws_iam_role.agent_init.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "agent_init_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [aws_ssm_parameter.agent_token.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# task role for agent
resource "aws_iam_role" "agent" {
  name               = "tfc-agent-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy_definition.json
}

data "aws_iam_policy_document" "agent_assume_role_policy_definition" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

# resource "aws_iam_role_policy" "agent_policy" {
#   name = "tfc-agent-policy"
#   role = aws_iam_role.agent.id

#   policy = data.aws_iam_policy_document.agent_policy_definition.json
# }

# data "aws_iam_policy_document" "agent_policy_definition" {
#   statement {
#     effect    = "Allow"
#     actions   = ["sts:AssumeRole"]
#     resources = [aws_iam_role.terraform_dev_role.arn]
#   }
# }

resource "aws_iam_role_policy_attachment" "agent_task_policy" {
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# networking for agents to reach internet
resource "aws_vpc" "main" {
  cidr_block = var.ip_cidr_vpc
}

resource "aws_subnet" "tfc_agent" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.ip_cidr_agent_subnet
  availability_zone = "${var.aws_region}a"
}

resource "aws_security_group" "tfc_agent" {
  name_prefix = "tfc-agent-sg"
  description = "Security group for tfc-agent-vpc"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress" {
  security_group_id = aws_security_group.tfc_agent.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # to peer to an HVN add your route here, for example
  #   route {
  #     cidr_block                = "172.25.16.0/24"
  #     vpc_peering_connection_id = "pcx-07ee5501175307837"
  #   }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.tfc_agent.id
  route_table_id = aws_route_table.main.id
}
