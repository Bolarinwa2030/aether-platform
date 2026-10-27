variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "image" {
  type = string
}
variable "container_port" {
  type = number
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "environment_vars" {
  type    = map(string)
  default = {}
}

variable "secrets" {
  type    = map(string)
  default = {}
} # name => Secrets Manager ARN

variable "health_check_grace_period" {
  type    = number
  default = 60
}

variable "log_retention_days" {
  type    = number
  default = 14
}