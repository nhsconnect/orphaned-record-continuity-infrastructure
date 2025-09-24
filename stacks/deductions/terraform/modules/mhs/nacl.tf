resource "aws_network_acl" "mhs_public" {
  vpc_id = aws_vpc.mhs_vpc.id
  subnet_ids = aws_subnet.mhs_public.*.id

  tags = {
    Name = "${var.environment}-${var.cluster_name}-mhs-inbound-nacl"
    Environment = var.environment
    CreatedBy = var.repo_name
  }
}

resource "aws_network_acl_rule" "ingress_sig" {
  count = length(var.inbound_sig_ips)
  network_acl_id = aws_network_acl.mhs_public.id
  protocol = -1
  rule_action = "allow"
  rule_number = 100 + count.index
  cidr_block = var.inbound_sig_ips[count.index]
}

resource "aws_network_acl_rule" "ingress_mhs_vpc" {
  network_acl_id = aws_network_acl.mhs_public.id
  protocol = -1
  rule_action = "allow"
  rule_number = 200
  cidr_block = var.mhs_vpc_cidr_block
}

resource "aws_network_acl_rule" "egress_sig" {
  count = length(var.inbound_sig_ips)
  network_acl_id = aws_network_acl.mhs_public.id
  egress = true
  protocol = -1
  rule_action = "allow"
  rule_number = 100 + count.index
  cidr_block = var.inbound_sig_ips[count.index]
}

resource "aws_network_acl_rule" "egress_mhs_vpc" {
  network_acl_id = aws_network_acl.mhs_public.id
  egress = true
  protocol = -1
  rule_action = "allow"
  rule_number = 200
  cidr_block = var.mhs_vpc_cidr_block
}

resource "aws_network_acl_rule" "ingress_gocd" {
  network_acl_id = aws_network_acl.mhs_public.id
  protocol = -1
  rule_action = "allow"
  rule_number = 300
  cidr_block = "${data.aws_ssm_parameter.gocd_nat_public_ip.value}/32"
}

resource "aws_network_acl_rule" "egress_gocd" {
  network_acl_id = aws_network_acl.mhs_public.id
  egress = true
  protocol = -1
  rule_action = "allow"
  rule_number = 300
  cidr_block = "${data.aws_ssm_parameter.gocd_nat_public_ip.value}/32"
}

data "aws_ssm_parameter" "gocd_nat_public_ip" {
  provider = aws.ci
  name = "/repo/prod/output/prm-gocd-infra/gocd-agent-public-ip"
}