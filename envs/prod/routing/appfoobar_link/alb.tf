resource "aws_lb" "this" {
  count = var.enable_alb ? 1 : 0

  name = "${local.name_prefix}-appfoobar-link"

  internal           = false
  load_balancer_type = "application"

  access_logs {
    # data.terraform_remote_state.remote_state に付けた名前.outputs.outputの名前
    bucket  = data.terraform_remote_state.log_alb.outputs.s3_bucket_this_id
    enabled = true
    prefix  = "appfoobar-link"
  }

  # HTTPSおよびHTTPSを受け付けられるようにする
  security_groups = [
    data.terraform_remote_state.network_main.outputs.security_group_web_id,
    data.terraform_remote_state.network_main.outputs.security_group_vpc_id
  ]

  subnets = [
    for s in data.terraform_remote_state.network_main.outputs.subnet_public : s.id
  ]

  tags = {
    Name = "${local.name_prefix}-appfoobar-link"
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_alb ? 1 : 0

  certificate_arn   = aws_acm_certificate.root.arn
  load_balancer_arn = aws_lb.this[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  # HTTPSに来たらターゲットグループに投げる
  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.foobar.arn
  }
}

# HTTPできたらHTTPSにリダイレクト
resource "aws_lb_listener" "redirect_http_to_https" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# デプロイを高速化したい場合は以下を参照
# https://toris.io/2021/04/speeding-up-amazon-ecs-container-deployments/
resource "aws_lb_target_group" "foobar" {
  name = "${local.name_prefix}-foobar"

  # ターゲット (本書であればタスク) を解除する (ALB から切り離す) 前に、ALB が待機する時間を指定
  deregistration_delay = 60
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.network_main.outputs.vpc_this_id

  # ヘルスチェックの指定
  health_check {
    # 異常なターゲットが正常であるとみなされるまでに必要なヘルスチェックの連続成功回数
    healthy_threshold   = 2
    # ヘルスチェックのインターバル
    interval            = 30
    # 正常とするステータス
    matcher             = 200
    # ヘルスチェクで使用するパス
    path                = "/"
    # ヘルスチェックで使用するポート。
    # 「"traffic-port"」を指定すると、ターゲットが ALB からのトラフィックを受信するポートが、
    # ヘルスチェックでも使用されます
    port                = "traffic-port"
    protocol            = "HTTP"
    # 指定した秒数の間、ターゲットからのレスポンスがないと、ヘルスチェックが失敗と見做される
    timeout             = 5
    # ターゲットが異常であるとみなされるまでに必要なヘルスチェックの連続失敗回数
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.name_prefix}-foobar"
  }
}
