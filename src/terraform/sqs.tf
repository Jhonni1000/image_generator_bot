locals {
  sqs_details = {
    message_size = 262144
    message_retention = 86400
    receive_wait_time = 10
    visibility_timeout = 60
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "request_DLQ_queue" {
  name = "telegram_requests_queue_DLQ"
}

# Main Queue
resource "aws_sqs_queue" "request_queue" {
  name                       = "telegram_requests_queue"
  max_message_size           = local.sqs_details.message_size
  message_retention_seconds  = local.sqs_details.message_retention
  receive_wait_time_seconds  = local.sqs_details.receive_wait_time
  visibility_timeout_seconds = local.sqs_details.visibility_timeout

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.request_DLQ_queue.arn
    maxReceiveCount     = 4
  })
}

# Queue Policy (Allow Lambda to send messages)
resource "aws_sqs_queue_policy" "request_queue_policy" {
  queue_url = aws_sqs_queue.request_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowLambdaSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.request_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_lambda_function.webhook_lambda.arn
          }
        }
      }
    ]
  })
}

# Redrive Allow Policy
resource "aws_sqs_queue_redrive_allow_policy" "request_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.request_DLQ_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.request_queue.arn]
  })
}
