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

provider "kubernetes" {
  config_context_cluster = aws_eks_cluster.example.name
}

# create deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
    labels = {
      app = "redis"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:latest"

          port {
            container_port = 6379
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "data"

          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      name       = "redis"
      port       = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_subnet" "example_a" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "example-subnet-a"
  }
}

resource "aws_subnet" "example_b" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "example-subnet-b"
  }
}

resource "aws_subnet" "example_c" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2c"
  tags = {
    Name = "example-subnet-c"
  }
}

resource "aws_eks_cluster" "example" {
  name     = "example-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.example_a.id,
      aws_subnet.example_b.id,
      aws_subnet.example_c.id,
    ]
  }
}

resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}