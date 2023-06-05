terraform {


  #aws dynamodb create-table \
  #  --table-name my-terraform-state-lock-table \
  #  --attribute-definitions AttributeName=LockID,AttributeType=S \
  #  --key-schema AttributeName=LockID,KeyType=HASH

  backend "s3" {
    bucket = "webapp.tf3.bucket"
    region = "us-east-2"
    key    = "sample_terraform.tfstate"
    dynamodb_table = "webapp-sample-terraform-state-lock-table"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.3"
}
