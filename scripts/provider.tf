terraform {
  required_providers {
    aws = {
      version = "~> 2.0"
      source  = "aws"
    }
  }

  required_version = ">= 1.0.4"
}

provider "aws" {
  region = "us-west-1"
}

data "aws_region" "Hello_region" {}

data "aws_caller_identity" "Hello_userId" {}