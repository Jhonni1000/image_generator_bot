variable "telegram_bot_token" {
  description = "Telegram bot token for sending messages"
  type        = string
}

variable "aws_region" {
    description = "AWS region"
    default = "us-east-1"
}