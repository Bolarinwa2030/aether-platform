resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-aether-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

variable "environment" { type = string }

output "arn" { value = aws_ecs_cluster.main.arn }
output "name" { value = aws_ecs_cluster.main.name }