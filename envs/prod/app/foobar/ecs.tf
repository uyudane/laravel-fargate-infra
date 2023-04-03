resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-${local.service_name}"

  # いつ落ちるか分からないということですが、Fargate Spot と通常のFargateは共存できます。つまり 「Fargate Spot が落ちた際は通常のFargate が自動で立ち上がる」という設定もできる。
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

resource "aws_ecs_task_definition" "this" {
  # タスク定義の名前
  family = "${local.name_prefix}-${local.service_name}"

  # タスクロールのARN
  task_role_arn = aws_iam_role.ecs_task.arn

  network_mode = "awsvpc"

  requires_compatibilities = [
    "FARGATE",
  ]

  # タスク実行ロールのARN
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  memory = "512"
  cpu    = "256"

  # タスクで動かすコンテナの設定
  container_definitions = jsonencode(
    [
      {
        # コンテナ名
        name  = "nginx"
        # イメージのURLとタグ
        image = "${module.nginx.ecr_repository_this_repository_url}:latest"

        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]

        # コンテナに渡す環境変数
        environment = []

        # パラメータストア、またはSecrets Managerを指定すると、その値がコンテナに環境変数として渡される
        secrets     = []

        dependsOn = [
          {
            containerName = "php"
            condition     = "START"
          }
        ]

        # ボリュームのマウントポイントを指定
        # P174 アプリ側のdocker-composeと合わせらてている。重要そう
        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        # コンテナのログ制限
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/nginx"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      },
      {
        name  = "php"
        image = "${module.php.ecr_repository_this_repository_url}:latest"

        portMappings = []

        environment = []
        secrets = [
          {
            name      = "APP_KEY"
            valueFrom = "/${local.system_name}/${local.env_name}/${local.service_name}/APP_KEY"
          }
        ]

        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/php"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )

  volume {
    name = "php-fpm-socket"
  }

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

resource "aws_ecs_service" "this" {
  # ECSサービスの名前を指定
  name = "${local.name_prefix}-${local.service_name}"

  # ECSクラスターのARNを指定
  cluster = aws_ecs_cluster.this.arn

  # キャパシティプロバイダー戦略
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    # タスクの最小限の数
    base              = 0
    # 起動済みタスクの総数に対する比率
    weight            = 1
  }

  platform_version = "1.4.0"

  # 使用するタスク定義のARNを指定
  task_definition = aws_ecs_task_definition.this.arn

  # 起動させておくタスク数
  desired_count                      = var.desired_count

  #ECS のデフォルトのデプロイ方法であるローリングアップデートでは、新しいタスクを起 動させた後、古いタスクを停止させることでタスクを入れ替えます。
  # この時、全体で最低何 個のタスクを起動している状態を維持するかを deployment_minimum_healthy_percent にパーセンテージで指定します。
  deployment_minimum_healthy_percent = 100

  # ローリングアップデート時に全体で最大何個までタスクを起動している状態にするか をパーセンテージで指定
  deployment_maximum_percent         = 200

  # ロードバランサーに関する設定
  load_balancer {
    # ロードバランサーがフォワードするコンテナ名とポート番号
    container_name   = "nginx"
    container_port   = 80
    # 設定するターゲットグループ
    target_group_arn = data.terraform_remote_state.routing_appfoobar_link.outputs.lb_target_group_foobar_arn
  }

  # タ スクの起動直後にこれらヘルスチェックで異常が出たとしても無視する猶予期間 (秒数) を 指定
  health_check_grace_period_seconds = 60

  # タスクのネットワーク設定
  network_configuration {
    # タスクにパブリックIPを割り当てるかを指定
    # タスクをプライベートサブネットで起動するため、パブリックIPは不要
    assign_public_ip = false
    security_groups = [
      data.terraform_remote_state.network_main.outputs.security_group_vpc_id
    ]
    # タスクが属するサブネットのID
    subnets = [
      for s in data.terraform_remote_state.network_main.outputs.subnet_private : s.id
    ]
  }

  # ECS Execを利用するかどうか
  enable_execute_command = true

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}
