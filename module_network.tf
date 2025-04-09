
module "networking" {
  source = "./modules/network"

  cidr_block_module = var.vpc_cidr_block_root[terraform.workspace]

  providers = {
    aws = aws
  }
}

