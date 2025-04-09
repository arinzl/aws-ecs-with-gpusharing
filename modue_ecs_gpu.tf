module "ecs" {
  source = "./modules/ecs-gpu"

  vpc_id               = module.networking.vpc-id
  asg_private_subnets  = module.networking.private_subnets
  asg_desired_capacity = var.ecs_gpu_cluster_asg_desired_size[terraform.workspace]

}
