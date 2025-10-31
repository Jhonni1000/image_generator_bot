resource "aws_dynamodb_table" "state-lock" {
  name = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "telegram-image-generator-backend-19999"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt = true
  }
}