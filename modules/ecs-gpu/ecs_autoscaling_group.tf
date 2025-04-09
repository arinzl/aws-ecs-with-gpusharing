resource "aws_autoscaling_group" "ecs_hosts" {
  name = "${var.app_name}-ecs-hosts"

  max_size              = 3
  min_size              = 1
  desired_capacity      = var.asg_desired_capacity
  desired_capacity_type = "units"
  force_delete          = true
  vpc_zone_identifier   = var.asg_private_subnets
  max_instance_lifetime = 60 * 60 * 24 * 7 # 1 week 

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      on_demand_allocation_strategy            = "lowest-price"
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 3
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs_host.id
        version            = "$Latest"
      }

      override {

        instance_requirements {
          memory_mib {
            min = 16384
            max = 32768
          }

          vcpu_count {
            min = 4
            max = 8
          }

          instance_generations = ["current"]

          accelerator_types         = ["gpu"]
          accelerator_manufacturers = ["nvidia"]
          allowed_instance_types    = ["g4*"]

          # gpu count
          accelerator_count {
            min = 1
            max = 4
          }
        }
      }

    }
  }

  instance_refresh {
    strategy = "Rolling"
  }


  tag {
    key                 = "Name"
    value               = "${var.app_name}-ECSHost"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "ecs_host" {
  name_prefix = "${var.app_name}-ecs-host-"
  image_id    = data.aws_ami.ecs_host.image_id

  instance_type = "g4dn.xlarge"

  user_data = base64encode(local.ecs_userdata)

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_host.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 40
      volume_type           = "gp3"
    }
  }

  vpc_security_group_ids = [aws_security_group.ecs_host.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}

locals {
  ecs_userdata = <<-EOF
    #!/bin/bash
    cat <<'DOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${aws_ecs_cluster.main.name}
    ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
    ECS_LOG_DRIVER=awslogs
    ECS_LOG_OPTS={"awslogs-group":"/aws/ecs/${var.app_name}-ecs-cluster","awslogs-region":"${data.aws_region.current.name}"}
    ECS_LOGLEVEL=info
    ECS_ENABLE_GPU_SUPPORT=true
    DOF

    sed -i 's/^OPTIONS="/OPTIONS="--default-runtime nvidia /' /etc/sysconfig/docker && echo '/etc/sysconfig/docker updated to have nvidia runtime as default' && systemctl restart docker && echo 'Restarted docker'
  EOF
}



## ASG Capacity Provider ##
resource "aws_ecs_capacity_provider" "hostecs_cp" {
  name = "hostecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_hosts.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 50
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.hostecs_cp.name]
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "ecs-gpu-scale-out"
  autoscaling_group_name = aws_autoscaling_group.ecs_hosts.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "ecs-gpu-scale-in"
  autoscaling_group_name = aws_autoscaling_group.ecs_hosts.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "ecs-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}
