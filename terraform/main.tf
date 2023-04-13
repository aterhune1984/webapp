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

# Define the VPC for the EKS cluster
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

# Define the private subnets for the EKS cluster


resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = cidrsubnet(aws_vpc.example_vpc.cidr_block, 4, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
  }
}

# Define the IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "example-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Define the IAM policy for the EKS cluster
resource "aws_iam_policy" "eks_cluster" {
  name        = "example-eks-cluster"
  policy      = data.aws_iam_policy_document.eks_cluster.json
}

# Define the IAM policy attachment for the EKS cluster
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = aws_iam_policy.eks_cluster.arn
  role       = aws_iam_role.eks_cluster.name
}

# Define the data source for the EKS cluster IAM policy document
data "aws_iam_policy_document" "eks_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]

    resources = [
      aws_eks_cluster.example_cluster.arn,
    ]
  }
}

# Define the EKS cluster
resource "aws_eks_cluster" "example_cluster" {
  name     = "example-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.private.*.id
    vpc_id     = aws_vpc.example_vpc.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}