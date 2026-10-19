terraform {
    backend "s3" {
        bucket      = "aether-platform-tfstate-dev"
        key         =   "vpc/terraform.tfstate"
        region      =   "us-east-1"
        dynamodb_table  =   "aether-platform-tflock-dev"
    }
}