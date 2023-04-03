# ECS サービスにおいて、ターゲットグループのARN を参照できるようにする
output "lb_target_group_foobar_arn" {
  value = aws_lb_target_group.foobar.arn
}
