resource "aws_sqs_queue" "request_queue" {
  name                       = "telegram_requests_queue"
  delay_seconds              = 90
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60

  redrive_allow_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.request_DLQ_queue.arn
    maxRecieveCount     = 4
  })
}

resource "aws_sqs_queue" "request_DLQ_queue" {
  name = "telegram_requests_queue_DLQ"
}

resource "aws_sqs_queue_redrive_allow_policy" "request_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.request_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.request_queue.arn]
  })
}

