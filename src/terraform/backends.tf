terraform {
  backend "s3" {
    bucket = "telegram-image-generator-backend-19999"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}