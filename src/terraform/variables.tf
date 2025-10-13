variable "telegram_bot_token" {
  description = "Telegram bot token for sending messages"
  type        = string
  sensitive   = true
}

variable "aws_region" {
    description = "AWS region"
    default = "us-east-1"
}