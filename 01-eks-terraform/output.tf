output "cluster_id" {
  value = aws_eks_cluster.krishna01.id
}

output "node_group_id" {
  value = aws_eks_node_group.krishna01.id
}

output "vpc_id" {
  value = aws_vpc.krishna01_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.krishna01_subnet[*].id
}
