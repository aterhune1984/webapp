
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
  region = "us-east-1"
}

resource "aws_eks_cluster" "default" {
  name = "my-eks-cluster"
  version = "1.21"

  # The following are optional configuration options.

  # The Kubernetes version to use for the cluster.
  #kubernetes_version = "1.21"

  # The number of Kubernetes control plane nodes to create.
  #control_plane_size = 3

  # The number of Kubernetes worker nodes to create.
  #node_group_count = 3

  # The type of Kubernetes worker nodes to create.
  #node_group_type = "t2.medium"

  # The VPC subnets to use for the Kubernetes worker nodes.
  #node_group_subnets = ["subnet-12345678", "subnet-87654321"]

  vpc_config {
    vpc_id = "vpc-12345678"
    subnets = ["subnet-12345678", "subnet-87654321"]
  }
}

resource "kubernetes_deployment" "redis" {
  name = "redis"
  replicas = 3
  selector = {
    app = "redis"
  }
  template {
    metadata {
      labels = {
        app = "redis"
      }
    }
    spec {
      containers {
        name = "redis"
        image = "redis:6.2.5"
        ports {
          containerPort = 6379
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  name = "redis"
  type = "LoadBalancer"
  selector = {
    app = "redis"
  }
  ports {
    port = 6379
    targetPort = 6379
  }
}}