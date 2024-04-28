terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket  = "tfstate-bucket-observability"
    key     = "build/terraform.tfstate"
    region  = "us-east-1"
  }
}
