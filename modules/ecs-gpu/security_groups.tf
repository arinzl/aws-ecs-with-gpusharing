# ASG EC2 Hosts
resource "aws_security_group" "ecs_host" {
  name        = "${var.app_name}-ecs-host"
  description = "SG for the EC2 Autoscaling group running the ECS tasks"
  vpc_id      = data.aws_vpc.network_vpc.id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-host"
  }
}
