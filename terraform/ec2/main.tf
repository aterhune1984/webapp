provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical owner ID
}


resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "ec2_kubernetes",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ec2_kubernetes_private"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ec2_kubernetes_public"
  }
  depends_on = [aws_route_table.public_route]
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "ec2_kubernetes_private",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.16.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "ec2_kubernetes_public",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id
}



resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ec2_kubernetes_gw"
  }
  depends_on = [aws_vpc.main]
}

resource "aws_route" "public_route" {
  route_table_id            = aws_route_table.public_route.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
  depends_on                = [aws_route_table.public_route]
}

resource "aws_nat_gateway" "private_natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw, aws_eip.nat_eip]
}

resource "aws_eip" "nat_eip" {
  vpc      = true
}

resource "aws_route" "private_nat_route" {
  route_table_id            = aws_route_table.private_route.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_natgw.id
  depends_on                = [aws_route_table.private_route, aws_nat_gateway.private_natgw]
}

resource "aws_security_group" "bastion_ssh" {
  name        = "ssh-bastion"
  description = "SSH Bastion Hosts"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "ssh to bastion"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_ssh.id]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true
  tags = {
    Name = "bastion"
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "k8smaster_role" {
  name               = "K8sMaster"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name = "autoscaler"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sClusterAutoscalerDescribe",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations"
            ],
            "Resource": "*"
        },
        {
            "Sid": "K8sClusterAutoscalerTaggedResourcesWritable",
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:UpdateAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
})
  }

  inline_policy {
    name = "cni"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sNodeAwsVpcCNI",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:AttachNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstances",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:AssignPrivateIpAddresses",
                "tag:TagResources"
            ],
            "Resource": "*"
        }
    ]
})
  }

  inline_policy {
    name = "ecr"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sECR",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
})
  }

    inline_policy {
      name   = "loadbalancing"
      policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sELB",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:AttachLoadBalancerToSubnets",
                "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateLoadBalancerPolicy",
                "elasticloadbalancing:CreateLoadBalancerListeners",
                "elasticloadbalancing:ConfigureHealthCheck",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteLoadBalancerListeners",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DetachLoadBalancerFromSubnets",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer"
            ],
            "Resource": "*"
        },
        {
            "Sid": "K8sNLB",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeLoadBalancerPolicies",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:SetLoadBalancerPoliciesOfListener"
            ],
            "Resource": "*"
        }
    ]
})

    }

    inline_policy {
    name = "master"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sMasterDescribeResources",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "K8sMasterAllResourcesWriteable",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateRoute",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:ModifyInstanceAttribute"
            ],
            "Resource": "*"
        },
        {
            "Sid": "K8sMasterTaggedResourcesWritable",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteRoute",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteVolume",
                "ec2:DetachVolume",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        }
    ]
})
  }

}

resource "aws_iam_role" "k8snode_role" {
  name               = "K8sNode"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name = "cni"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sNodeAwsVpcCNI",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:AttachNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstances",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:AssignPrivateIpAddresses",
                "tag:TagResources"
            ],
            "Resource": "*"
        }
    ]
})
  }

  inline_policy {
    name = "ecr"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sECR",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
})
  }
  inline_policy {
    name = "node"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "K8sNodeDescribeResources",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeRegions"
            ],
            "Resource": "*"
        }
    ]
})
  }

}

resource "aws_instance" "ami_build_instance" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
  user_data     = <<-EOF
    #!/bin/bash
    printf "[Service]\nExecStartPost=/sbin/iptables -P FORWARD ACCEPT" |   sudo tee /etc/systemd/system/docker.service.d/10-iptables.conf
    apt-get install -y docker.io
    docker version
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    EOF
  tags = {
    Name = "ami_build_instance"
  }
}

resource "aws_ami_from_instance" "kube_ami"{
  name = "kube_ami"
  source_instance_id = aws_instance.ami_build_instance.id
}