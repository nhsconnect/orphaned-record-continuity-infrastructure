resource "aws_vpc_peering_connection" "core_private" {
  peer_vpc_id = local.deductions_private_vpc_id
  vpc_id      = local.deductions_core_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name        = "${var.environment}-deductions-core-private-peering"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}
