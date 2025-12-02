output "vpc_id" {
  value = local.mhs_vpc_id
}

output "private_mhs_vpc_peering_id" {
  value = aws_vpc_peering_connection.private_mhs.id
}