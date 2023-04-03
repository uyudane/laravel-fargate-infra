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

# GitHub Actions 上で実行させる ecspresso に tfstate(S3 オブジェクト) を参照させるための読み取り権限
# 該当の tfstate 読み取り権限をインライン ポリシーとして作成し、デプロイ用の IAM ロールにアタッチ
resource "aws_iam_role_policy" "s3" {
  name = "s3"
  role = aws_iam_role.deployer.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : "arn:aws:s3:::shonansurvivors-tfstate/${local.system_name}/${local.env_name}/cicd/app_${local.service_name}_*.tfstate"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject"
          ],
          "Resource" : "${data.aws_s3_bucket.env_file.arn}/*"
        },
      ]
    }
  )
}

# デプロイ用 IAM ロールに、サービスやタスク定義を更新する権限を追加
resource "aws_iam_role_policy" "ecs" {
  name = "ecs"
  role = aws_iam_role.deployer.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "RegisterTaskDefinition",
          "Effect" : "Allow",
          "Action" : [
            "ecs:RegisterTaskDefinition"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "PassRolesInTaskDefinition",
          "Effect" : "Allow",
          "Action" : [
            "iam:PassRole"
          ],
          "Resource" : [
            data.aws_iam_role.ecs_task.arn,
            data.aws_iam_role.ecs_task_execution.arn,
          ]
        },
        {
          "Sid" : "DeployService",
          "Effect" : "Allow",
          "Action" : [
            "ecs:UpdateService",
            "ecs:DescribeServices"
          ],
          "Resource" : [
            data.aws_ecs_service.this.arn
          ]
        }
      ]
    }
  )
}
