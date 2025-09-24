output "subnet_ids" {
  value = aws_subnet.mhs_subnet.*.id
}