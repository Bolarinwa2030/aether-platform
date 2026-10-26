module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  name                 = "aether-platform-dev"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Application LOad Balancer 
module "alb" {
  source            = "../../modules/alb"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_groups   = [module.vpc.alb_security_group_id]

}

# ECS module
module "ecs" {
  source            = "../../modules/ecs"
  environment       = "dev"
  container_image   = "nginx:latest"
  ecs_execution_role_arn  = var.ecs_execution_role_arn
  private_subnet_ids      = module.vpc.private_subnet_ids
  security_groups         = [module.vpc.ecs_security_group_id]
  target_group_arn        = module.alb.target_group_arn 
  alb_listener_dependency = module.alb.listener_arn

}

# RDS module 

module "rds" {
  source        = "../../modules/rds"
  environment   = "dev"
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_groups   = [module.vpc.rds_security_group_id]
  db_username       = "aetheradmin"
  db_password       = var.db_password 
}