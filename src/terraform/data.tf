data "archive_file" "telegram_worker_zip" {
    type        = "zip"
    source_dir  = "${path.module}/../scripts/worker_lambda"
    output_path = "${path.module}/../scripts/worker_lambda.zip"
}

data "archive_file" "telegram_webhook_zip" {
    type        = "zip"
    source_dir  = "${path.module}/../scripts/webhook_lambda"
    output_path = "${path.module}/../scripts/webhook_lambda.zip"
}