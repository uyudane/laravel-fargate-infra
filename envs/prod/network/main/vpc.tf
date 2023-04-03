resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  # プライベートホストゾーンでの名前解決に使用
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.name_prefix}-main"
  }
}
