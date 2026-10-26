variable "environment" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "noncurrent_version_days" {
  type    = number
  default = 30
}