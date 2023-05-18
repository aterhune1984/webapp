variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  type        = string
  default     = "ec2_kube"
  description = "Name of the Kubernetes cluster"
}

variable "key_name" {
  type        = string
  default     = "aterhune"
  description = "Name of the your key"
}
