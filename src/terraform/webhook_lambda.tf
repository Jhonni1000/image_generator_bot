resource "aws_iam_role" "webhook_lambda_role" {
    name = "webhook_lambda_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
                Service = "lambda.amazonaws.com"
            }
        }]

    })
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_role" {
    role = aws_iam_role.webhook_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "webhook_lambda_role" {
    name = "lambda-sqs-policy"
    role = aws_iam_role.webhook_lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = ["sqs:SendMessage"]
            Effect = "Allow"
            Resource = aws_sqs_queue.request_queue.arn
        }]
    })
}

resource "aws_lambda_function" "webhook_lambda" {
    function_name = "telegram-webhook-lambda"
    runtime = "python3.9"
    role = aws_iam_role.webhook_lambda_role.arn
    handler = "webhook_lambda.lambda_handler"

    filename = data.archive_file.telegram_webhook_zip.output_path
    source_code_hash = data.archive_file.telegram_webhook_zip.output_base64sha256

    environment {
        variables = {
            QUEUE_URL = aws_sqs_queue.request_queue.url
        }
    }
}

resource "aws_lambda_permission" "webhook_lambda" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.webhook_lambda.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.image_generator_bot.execution_arn}/*/*"
}