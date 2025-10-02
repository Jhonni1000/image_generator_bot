# AI Image Generator Telegram Bot

This project is a Telegram bot that generates AI-powered images based on user prompts.
It is built using AWS Lambda, API Gateway, SQS, Bedrock FMs (Stable Diffusion), and S3 for scalable, serverless image generation.

## Features

* Users chat with the bot on Telegram and send text prompts.
* The bot generates AI images using Amazon Bedrock foundation models.
* Generated images are stored in Amazon S3 and delivered back to the user.
* Built with serverless architecture for easy scaling and low cost.
* Designed for extension (future support for audio, video, or more models).

## Architecture Overview
        Telegram   →   API Gateway   →   Webhook Lambda   →   SQS   →   Worker Lambda   →   Bedrock   →   S3   →   Telegram


