# ALB を作成する際に S3 バケットの ID が必要になってくるので、これを参照できるよう にします
# Terraform では、ある tfstate において output として宣言された値を、
# terraform_remote_state というデータソースを使うことで、別のディレクトリから参照する ことが可能です
output "s3_bucket_this_id" {
  value = aws_s3_bucket.this.id
}
