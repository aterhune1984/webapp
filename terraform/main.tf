# Declare the provider for AWS
provider "aws" {
  region = "us-east-2"
}

# Declare the VPC resource
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Declare the subnets
resource "aws_subnet" "example_subnet_a" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "example_subnet_b" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

# Declare the EKS cluster
resource "aws_eks_cluster" "example_cluster" {
  name     = "example-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.example_subnet_a.id,
      aws_subnet.example_subnet_b.id,
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# Declare the EKS node group
# Declare the EKS node group
resource "aws_eks_node_group" "example_node_group" {
  cluster_name    = aws_eks_cluster.example_cluster.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  remote_access {
    ec2_ssh_key = ""
    source_security_group_id = aws_security_group.example_sg.id
  }

  subnet_ids = [
    aws_subnet.example_subnet_a.id,
    aws_subnet.example_subnet_b.id,
  ]

  depends_on = [aws_eks_cluster.example_cluster]
}

resource "aws_iam_role" "eks_node" {
  name = "eks-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Declare the IAM role and policy for the EKS cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

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

resource "aws_iam_policy" "eks_cluster" {
  name        = "eks-cluster"
  path        = "/"
  policy      = data.aws_iam_policy_document.eks_cluster.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = aws_iam_policy.eks_cluster.arn
  role       = aws_iam_role.eks_cluster.name
}

data "aws_iam_policy_document" "eks_cluster" {
  statement {
    actions = [
      "eks:DescribeCluster",
    ]
    resources = [
      aws_eks_cluster.example_cluster.arn,
    ]
  }
}

# Declare the security group for the EKS node group
resource "aws_security_group" "example_sg" {
  name_prefix = "example-sg"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}