resource "aws_iam_user" "github" {
  name = "${local.name_prefix}-${local.service_name}-github"

  tags = {
    Name = "${local.name_prefix}-${local.service_name}-github"
  }
}

# デプロイに必要な権限を持つ IAMロール
resource "aws_iam_role" "deployer" {
  name = "${local.name_prefix}-${local.service_name}-deployer"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole",
            # 本書では、aws-actions/configure-aws-credentials の機能を利用して Assume Role を行 いますが、
            # このアクションによる Assume Role ではデフォルトでセッションタグと呼ばれ ものの受け渡しが行われます。
            # その際に sts:TagSession という権限が許可されていないと エラーになるため、ここでは指定するようにしています。
            "sts:TagSession"
          ],
          # この IAM ロールがどんな AWS リソースから Assume Role されることを許可するかを記述
          # IAM ユーザー example-prod-foobar-github からの Assume Role が許可
          "Principal" : {
            "AWS" : aws_iam_user.github.arn
          }
        }
      ]
    }
  )

  tags = {
    Name = "${local.name_prefix}-${local.service_name}-deployer"
  }
}

data "aws_iam_policy" "ecr_power_user" {
  #ECR の読み書きを行う権限を持ってい ます。ECR にイメージをプッシュするにあたって必要な権限が揃っている
  # 本来は foobar アプリケーションに 関連する ECR のみ読み書きできるようにするのが理想的
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "role_deployer_policy_ecr_power_user" {
  role       = aws_iam_role.deployer.name
  policy_arn = data.aws_iam_policy.ecr_power_user.arn
}
