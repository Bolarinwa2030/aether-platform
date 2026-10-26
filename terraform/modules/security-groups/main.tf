locals {
  app_ports = { for p in var.app_ports : tostring(p) => p }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-aether-alb-"
  description = "Application Load Balancer"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-aether-alb-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.environment}-aether-ecs-"
  description = "ECS Fargate tasks"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-aether-ecs-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-aether-rds-"
  description = "RDS PostgreSQL"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.environment}-aether-rds-sg" }

  lifecycle { create_before_destroy = true }
}

# ---- ALB ----
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  for_each                     = local.app_ports
  security_group_id            = aws_security_group.alb.id
  description                  = "To ECS tasks on ${each.value}"
  from_port                    = each.value
  to_port                      = each.value
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}

# ---- ECS ----
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  for_each                     = local.app_ports
  security_group_id            = aws_security_group.ecs.id
  description                  = "From ALB on ${each.value}"
  from_port                    = each.value
  to_port                      = each.value
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS out (ECR, Secrets Manager, CloudWatch Logs)"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To RDS"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

# ---- RDS (no egress rules at all) ----
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "From ECS tasks"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}