resource "aws_security_group" "vault-server" {
  name        = "vault-server-sg"
  description = "SSH and Internal Traffic"

  vpc_id = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault API traffic
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault cluster traffic
  # ingress {
  #   from_port   = 8201
  #   to_port     = 8201
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Internal Traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Internal Traffic from agents
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.security_group_allowed]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}