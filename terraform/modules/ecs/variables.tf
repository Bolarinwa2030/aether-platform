variable "environment" { 
    type = string 
    }

variable "container_image" { 
    type = string 
    }

variable "ecs_execution_role_arn" { 
    type = string 
    }

variable "private_subnet_ids" { 
    type = list(string) 
    }

variable "security_groups" { 
    type = list(string) 
    }

variable "target_group_arn" { 
    type = string 
    }

variable "alb_listener_listener_dependency" { 
    type = any 
    }