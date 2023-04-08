resource "aws_elasticache_replication_group" "this" {
  engine = "redis"

  // Redis settings
  replication_group_id          = "${local.system_name}-${local.env_name}-${local.service_name}"
  # 説明文 省略不可
  replication_group_description = "Session storage for Laravel"
  engine_version                = "6.x"
  port                          = 6379
  parameter_group_name          = aws_elasticache_parameter_group.this.name
  # ノードタイプ
  # 低スペックの場合、ElastiCache の新規作成処理に 10 分程度かかる
  node_type                     = "cache.t3.micro"

  # 2 つのノードが作成され、異なるアベイラビリティゾーンにそれぞれ 1ノードずつ配置されます
  number_cache_clusters         = 2
  multi_az_enabled              = true

  // Advanced Redis settings
  subnet_group_name = data.terraform_remote_state.network_main.outputs.elasticache_subnet_group_this_name

  // Security
  security_group_ids = [
    data.terraform_remote_state.network_main.outputs.security_group_cache_foobar_id
  ]

  # ElastiCache に保存するデータを暗号化するかどうか
  at_rest_encryption_enabled = true

  # ElastiCache との通信を暗号化するかどうか
  transit_encryption_enabled = false

  // Backup
  snapshot_retention_limit = 1
  snapshot_window          = "17:00-18:00"

  // Maintenance
  maintenance_window     = "fri:18:00-fri:19:00"

  # ElastiCache では、発生した様々なイベント (フェイルオーバーなど) を
  # Amazon SNS(Simple Notification Service) に通知することができます
  notification_topic_arn = ""

  // Others
  # 読み書き用のプライマリーノードに障害が発生した時、読み取り専用のレプリカノードを 自動でプライマリーノードへ切り替えるかどうか
  automatic_failover_enabled = true
  auto_minor_version_upgrade = false

  tags = {
    Name = "${local.system_name}-${local.env_name}-${local.service_name}"
  }
}
