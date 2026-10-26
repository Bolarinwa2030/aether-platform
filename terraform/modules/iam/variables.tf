# modules/iam/variables.tf
variable "environment" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "bucket_arn" {
  type = string
}