data "aws_ami" "amazon-linux-2" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = var.region
}


resource "aws_instance" "test" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  tags = {
    Name = "test"
  }
}

resource "aws_instance" "mywebserver2" {
  ami = "ami-01107263728f3bef4"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  availability_zone = "us-east-2b"
  tags = {
    Name = "mywebserver2"
  }
}
