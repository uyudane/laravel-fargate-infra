# 自分のAWSアカウントIDが参照できる
data "aws_caller_identity" "self" {}

data "aws_region" "current" {}
