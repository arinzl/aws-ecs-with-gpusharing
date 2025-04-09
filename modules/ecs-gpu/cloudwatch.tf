resource "aws_cloudwatch_log_group" "ecs_cluster" {

  name = "/aws/ecs/${var.app_name}-ecs-cluster"

  kms_key_id        = aws_kms_key.kms_key.arn
  retention_in_days = var.cloudwatch_log_retention

  tags = {
    Name = "${var.app_name}-ecs-cluster"
  }
}

resource "aws_cloudwatch_log_group" "ecs_task" {
  name = "/aws/ecs/${var.app_name}-ecs-task"

  kms_key_id        = aws_kms_key.kms_key.arn
  retention_in_days = var.cloudwatch_log_retention

  tags = {
    Name = "${var.app_name}-ecs-task"
  }
}

