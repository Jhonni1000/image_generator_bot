resource "aws_lambda_layer_version" "requests_layer" {
  filename   = "${path.module}/../scripts/requests_layer.zip" 
  layer_name = "requests-layer"
  compatible_runtimes = ["python3.9"]
  description = "Python requests library for Lambda"
}

resource "aws_s3_bucket" "telegram_bot_bucket" {
    bucket = "telegram-bot-bucket-19999"
    object_lock_enabled = true
}

resource "aws_s3_bucket_versioning" "telegram_bot_bucket" {
    bucket = aws_s3_bucket.telegram_bot_bucket.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_object_lock_configuration" "telegram_bot_bucket" {
    bucket = aws_s3_bucket.telegram_bot_bucket.id

    rule {
        default_retention {
            mode = "COMPLIANCE"
            days = 5
        }
    }
}

resource "aws_iam_role" "worker_lambda_role" {
    name = "worker_lambda_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Principal = {
                Service = "lambda.amazonaws.com"
            },
            Effect = "Allow"
        }]
    })
}

resource "aws_iam_policy" "worker_lambda_role_policy" {
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Sid = "WorkerLambdaPolicyBedrock",
                Effect = "Allow",
                Action = [ 
                    "bedrock:InvokeModel", 
                    "bedrock:InvokeModelWithResponseStream" 
                ],
                Resource = "*"
            },

            {
                Sid = "WorkerLambdaPolicyS3",
                Effect = "Allow",
                Action = [
                        "s3:PutObject", 
                        "s3:GetObject"
                    ]
                Resource = [ 
                    aws_s3_bucket.telegram_bot_bucket.arn, 
                    "${aws_s3_bucket.telegram_bot_bucket.arn}/*" 
                ]
            }
        
        ]
    })
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_policy1" {
    role = aws_iam_role.worker_lambda_role.name
    policy_arn = aws_iam_policy.worker_lambda_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_lambda_role_policy2" {
    role = aws_iam_role.worker_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "worker_lambda" {
    function_name = "telegram-worker-lambda"
    runtime = "python3.9"
    role = aws_iam_role.worker_lambda_role.arn
    handler = "worker_lambda.lambda_handler"
    timeout = 60

    filename = data.archive_file.telegram_worker_zip.output_path
    source_code_hash = data.archive_file.telegram_worker_zip.output_base64sha256

    environment {
        variables = {
            TELEGRAM_BOT_TOKEN = var.telegram_bot_token
            S3_BUCKET = aws_s3_bucket.telegram_bot_bucket.bucket
            REGION = var.aws_region
            BEDROCK_MODEL_ID = "amazon.titan-image-generator-v2:0"  
        }
    }

    reserved_concurrent_executions = 5
    
    layers = [ aws_lambda_layer_version.requests_layer.arn ]
}

resource "aws_lambda_event_source_mapping" "worker_lambda_trigger" {
    event_source_arn = aws_sqs_queue.request_queue.arn
    function_name = aws_lambda_function.worker_lambda.function_name
    batch_size = 1
    enabled = true
}