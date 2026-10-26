data "aws_caller_identity" "current" {}

locals {
  name = "aether-platform-${var.environment}"
}

module "vpc" {
  source               = "../../modules/vpc"
  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway # true in dev, false in prod
}

module "security_group" {
  source      = "../../modules/security-groups"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "ecr" {
  source       = "../../modules/ecr"
  environment  = var.environment
  repositories = ["aether-backend", "aether-frontend"]
}

module "iam" {
  source        = "../../modules/iam"
  environment   = var.environment
  db_secret_arn = module.rds.password_secret_arn
  bucket_arn    = module.s3.bucket_arn
}

module "alb" {
  source            = "../../modules/alb"
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_groups   = [module.security_group.alb_security_group_id]
  certificate_arn   = var.certificate_arn # null in dev until you have a domain

  services = {
    frontend = { port = 8080, health_path = "/healthz" }
    backend  = { port = 8000, health_path = "/healthz", path_patterns = ["/api/*"], priority = 10 }
  }
}

module "ecs_cluster" {
  source      = "../../modules/ecs-cluster"
  environment = var.environment
}

module "backend" {
  source             = "../../modules/ecs-service"
  name               = "aether-backend"
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.arn
  image              = "${module.ecr.repository_urls["aether-backend"]}:${var.backend_image_tag}"
  container_port     = 8000
  cpu                = var.backend_cpu
  memory             = var.backend_memory
  desired_count      = var.backend_desired_count
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  subnet_ids         = module.vpc.private_subnet_ids
  security_groups    = [module.security_group.ecs_security_group_id]
  target_group_arn   = module.alb.target_group_arns["backend"]


  environment_vars = {
    AETHER_ENVIRONMENT = var.environment
    DB_HOST            = module.rds.address
    DB_PORT            = tostring(module.rds.port)
    DB_NAME            = module.rds.db_name
    DB_USER            = var.db_username
  }
  secrets = {
    DB_PASSWORD = "${module.rds.password_secret_arn}:password::"
  }
}

module "frontend" {
  source             = "../../modules/ecs-service"
  name               = "aether-frontend"
  environment        = var.environment
  cluster_arn        = module.ecs_cluster.arn
  image              = "${module.ecr.repository_urls["aether-frontend"]}:${var.frontend_image_tag}"
  container_port     = 8080
  cpu                = var.frontend_cpu
  memory             = var.frontend_memory
  desired_count      = var.frontend_desired_count
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  subnet_ids         = module.vpc.private_subnet_ids
  security_groups    = [module.security_group.ecs_security_group_id]
  target_group_arn   = module.alb.target_group_arns["frontend"]
  # nginx proxies /api to this; with ALB path routing it is not strictly needed
  environment_vars = { BACKEND_URL = "http://${module.alb.dns_name}" }
}

module "rds" {
  source             = "../../modules/rds"
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  security_groups    = [module.security_group.rds_security_group_id]
  db_username        = var.db_username
  # password generated inside the module and stored in Secrets Manager
}

module "s3" {
  source        = "../../modules/s3"
  environment   = var.environment
  bucket_name   = "aether-assets-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # dev only; leave false in prod
}