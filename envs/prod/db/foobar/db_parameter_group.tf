# MySQL、PostgreSQL といった DB エンジンごとの固有 のパラメータを設定・管理する AWS リソースです
resource "aws_db_parameter_group" "this" {
  name = "${local.system_name}-${local.env_name}-${local.service_name}"

  family = "mysql8.0"

  # 文字コードは utf8mb4 とする
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  # 照合順序 (collations) は utf8mb4_0900_ai_ci とする
  parameter {
    name  = "collation_server"
    value = "utf8mb4_0900_ai_ci"
  }

  # 一般ログ (general_log) を出力する
  parameter {
    name  = "general_log"
    value = "1"
  }

  # 1 秒以上 (long_query_time で指定) のクエリをスロークエリログ(slow_query_log) として出力する
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "1.0"
  }

  # ログは CloudWatch Logs に出力する (log_output に FILE を指定)
  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Name = "${local.system_name}-${local.env_name}-${local.service_name}"
  }
}
