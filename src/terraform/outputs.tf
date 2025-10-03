output "telegram_webhook_url" {
  value = "${aws_apigatewayv2_api.image_generator_bot.api_endpoint}/webhook"
}