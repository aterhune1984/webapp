output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_dns" {
  value = aws_instance.bastion.private_dns
}

output "k8s_master_private_dns" {
  value = aws_instance.kubernetes_master.private_dns
}
