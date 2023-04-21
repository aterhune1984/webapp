# Create EKS cluster
# super basic eks cluster to play with kubernetes,  this is not an ideal configuration, use at your own risk

provider "aws" {
  region = "us-east-2"
}

resource "aws_eks_cluster" "example_cluster" {
  name     = "example-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private0.id,
      aws_subnet.private1.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

# Create IAM role for EKS cluster
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

# Attach IAM policy to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Create VPC and subnets
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "private0" {

  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example_vpc.id
  availability_zone = "us-east-2a"

  tags = {
    Name = "example-private-0"
  }
}

resource "aws_subnet" "private1" {

  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.example_vpc.id
  availability_zone = "us-east-2b"

  tags = {
    Name = "example-private-1"
  }
}
# Create worker node group
resource "aws_eks_node_group" "example_node_group" {
  cluster_name    = aws_eks_cluster.example_cluster.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  instance_types = ["t3.medium"]
  subnet_ids     = [aws_subnet.private0.id, aws_subnet.private1.id ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group,
  ]
}

# Create IAM role for worker nodes
resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group"

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

# Attach IAM policy to worker node role
resource "aws_iam_role_policy_attachment" "eks_node_group" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

# Add additional policies to worker node role as needed
resource "aws_iam_role_policy_attachment" "eks_node_group_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}