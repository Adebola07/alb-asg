terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    backend "s3" {
     bucket = "main-bucket-07"
     key    = "remote/state-file"
     region = "us-east-1"
   }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
