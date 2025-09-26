output "cluster_id" {
  value = aws_eks_cluster.devopsbykrishna.id
}

output "node_group_id" {
  value = aws_eks_node_group.devopsbykrishna.id
}

output "vpc_id" {
  value = aws_vpc.devopsbykrishna_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.devopsbykrishna_subnet[*].id
}

