resource "aws_vpc_peering_connection" "private_mhs" {
  peer_vpc_id = var.deductions_private_vpc_id
  vpc_id = local.mhs_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "${var.environment}-${var.cluster_name}-deductions-private-mhs-peering"
    CreatedBy   = var.repo_name
    Environment = var.environment
  }
}