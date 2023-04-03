terraform {
  backend "s3" {
    bucket = "yudai-tfstate"
    key    = "example/prod/log/app_foobar_v1.0.0.tfstate"
    region = "ap-northeast-1"
  }
}
