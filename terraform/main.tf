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


resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7.cluster.on"
  engine_version       = "7.0.7"
  port                 = 6379
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cluster_address
}