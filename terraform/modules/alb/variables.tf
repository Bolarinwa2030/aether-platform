variable "environment"       { 
    type = string 
    }

variable "vpc_id"            { 
    type = string 
    }

variable "public_subnet_ids" { 
    type = list(string) 
    }

variable "security_groups"   { 
    type = list(string) 
    }

variable "services" {
  type = map(object({
    port          = number
    health_path   = string
    path_patterns = optional(list(string), [])
    priority      = optional(number, 0)
  }))
}

variable "default_service" {
  type    = string
  default = "frontend"
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "deregistration_delay" {
  type    = number
  default = 30
}

