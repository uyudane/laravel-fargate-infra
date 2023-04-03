resource "aws_eip" "nat_gateway" {
  # 三項演算子
  # var.enable_nat_gatewayがtrueの場合はlocal.nat_gateway_azsのAZ分作成
  # falseの場合は作成しない
  for_each = var.enable_nat_gateway ? local.nat_gateway_azs : {}

  vpc = true

  tags = {
    Name = "${aws_vpc.this.tags.Name}-nat-gateway-${each.key}"
  }
}
