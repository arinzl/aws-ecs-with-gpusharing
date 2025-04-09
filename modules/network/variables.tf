variable "cidr_block_module" {
  description = "The cidr block for the account"
  type        = string
}


variable "app_name" {
  description = "Name of application or project"
  type        = string
  default     = "ecs-gpu"
}


