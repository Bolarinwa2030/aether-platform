variable "vpc_cidr" {
    type        =   string
    description =   "CIDR BLOCK"
    default     =   "10.0.0.0/16"
}

variable "name" {
    type            =   string
    description     =   "VPC Name"
    default         = "aether-platform-vpc-dev"

}

variable "public_subnet_cidrs {
    type    = list(string)
    default =   ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    type    =   list(string)
    default =   ["10.0.11.0/24", "10.0.20.0/24"]
}

variable "azs" {
    type    =   list(string)
    default =   ["us-east-1a", "us-east-1b"]
}