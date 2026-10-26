variable "environment" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region for this environment"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "db_username" {
  type    = string
  default = "aether_admin"
}

variable "backend_image_tag" {
  type = string
}

variable "frontend_image_tag" {
  type = string
}

variable "backend_cpu" {
  type    = number
  default = 256
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "backend_desired_count" {
  type    = number
  default = 1
}

variable "frontend_cpu" {
  type    = number
  default = 256
}

variable "frontend_memory" {
  type    = number
  default = 512
}

variable "frontend_desired_count" {
  type    = number
  default = 1
}