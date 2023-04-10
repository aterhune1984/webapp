terraform {
 required_providers {
   aws = {
     source = "hashicorp/aws"
   }
 }

 backend "s3" {
   region = "us-east-2"
   key    = "terraform.tfstate"
 }
}

provider "aws" {
 region = "us-east-2"
}

resource "aws_instance" "test_instance" {
 ami           = "ami-0103f211a154d64a6"
 instance_type = "t2.nano"
 tags = {
   Name = "test_instance"
 }
}