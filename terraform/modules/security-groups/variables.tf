variable "environment" { 
    type = string 
}

variable "vpc_id"      { 
    type = string 
}


variable "app_ports" {
  type    = list(number)
  default = [8000, 8080]
}

variable "db_port" {
  type    = number
  default = 5432
}