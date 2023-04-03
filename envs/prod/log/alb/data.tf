# WS が ELB(Elastic Load Balancer) の管理を行なっている AWS アカウント ID を参照
data "aws_elb_service_account" "current" {}
