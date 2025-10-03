resource "aws_apigatewayv2_api" "image_generator_bot" {
  name          = "image_generator_bot_api"
  description   = "This is an API for telegram image generator bot"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "image_generator_bot" {
  api_id                 = aws_apigatewayv2_api.image_generator_bot.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.webhook_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "image_generator_bot" {
  api_id    = aws_apigatewayv2_api.image_generator_bot.id
  route_key = "POST/webhook"
  target    = "integrations/${aws_apigatewayv2_integration.image_generator_bot.id}"
}

resource "aws_apigatewayv2_stage" "image_generator_bot" {
  api_id      = aws_apigatewayv2_api.image_generator_bot.id
  name        = "$default"
  auto_deploy = true
}