provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aether-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}