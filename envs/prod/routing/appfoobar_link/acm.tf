resource "aws_acm_certificate" "root" {
  # ドメイン名
  domain_name = data.aws_route53_zone.this.name

  # ドメインの所有権の検証
  validation_method = "DNS"

  tags = {
    Name = "${local.name_prefix}-appfoobar-link"
  }

  # 新しいリソースを作成してから古いリソースを削除
  lifecycle {
    create_before_destroy = true
  }
}

# 実際に何か AWS リソースを作成するわ けではなく、
# apply すると DNS 検証が完了するまで待ち、検証が完了すると apply が完了 します。
resource "aws_acm_certificate_validation" "root" {
  certificate_arn = aws_acm_certificate.root.arn
}
