
variable "region" {
  default = "ap-southeast-2"
  type    = string
}

variable "vpc_cidr_block_root" {
  type        = map(string)
  description = "VPD CIDR ranges per terraform workspace"
  default = {
    "default" : "10.32.0.0/16",
    "prod" : "10.16.0.0/16",
    "non-prod" : "10.32.0.0/16",
  }
}

variable "app_name" {
  default = "ecs-gpu"
  type    = string
}

variable "ecs_gpu_cluster_asg_desired_size" {
  type        = map(number)
  description = "Number of desired ecs instances in ecs cluster in auto scaling group"
  default = {
    "prod"     = 2,
    "non-prod" = 1,
    default    = 1,
  }
}
