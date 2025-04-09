data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "ecs_host" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-2.0*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "network_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  depends_on = [
    data.aws_vpc.network_vpc
  ]
  filter {
    name   = "tag:Name"
    values = ["${var.app_name}-private*"]
  }
}
