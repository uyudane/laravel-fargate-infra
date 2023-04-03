locals {
  # var.single_nat_gatewayがtrueの場合は、AZは一つ分だけ作成する
  nat_gateway_azs = var.single_nat_gateway ? { keys(var.azs)[0] = values(var.azs)[0] } : var.azs
}
