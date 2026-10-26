variable "ecs_execution_role_arn" {
  type        = string
  description = "IAM role ARN granting ECS permissions to pull images and write logs"
}

variable "db_password" {
  type        = string
  description = "Master password for the RDS database instance"
  sensitive   = true
}