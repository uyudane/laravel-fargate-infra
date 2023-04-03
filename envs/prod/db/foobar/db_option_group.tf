# DB オプショングループは、データベースの管理やセキュリティを強化する機能を設定・管理する AWS リソースです
# 今回はほぼ空の状態
resource "aws_db_option_group" "this" {
  name = "${local.system_name}-${local.env_name}-${local.service_name}"

  engine_name          = "mysql"
  major_engine_version = "8.0"

  tags = {
    Name = "${local.system_name}-${local.env_name}-${local.service_name}"
  }
}
