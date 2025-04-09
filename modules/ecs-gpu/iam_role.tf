
#### ECS EC2 Host Role ####
resource "aws_iam_role" "ecs_host" {
  name               = "${var.app_name}-ecs-host"
  assume_role_policy = data.aws_iam_policy_document.ecs_host_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

}

data "aws_iam_policy_document" "ecs_host_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_instance_profile" "ecs_host" {
  name = aws_iam_role.ecs_host.name
  role = aws_iam_role.ecs_host.id
}


#### ECS Common Task & TaskExecution Roles #####

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#### ECS TaskExecution Role #####
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

#### ECS Task Role #####

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app_name}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json

}


resource "aws_iam_role_policy" "ecs_task" {
  name   = aws_iam_role.ecs_task_role.name
  role   = aws_iam_role.ecs_task_role.id
  policy = data.aws_iam_policy_document.ecs_task.json
}


data "aws_iam_policy_document" "ecs_task" {
  statement {
    sid = "taskcwlogging"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "encryptionOps"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.kms_key.arn,
    ]
  }

}

