import json
import os
import boto3
import base64
import requests
import uuid
from botocore.exceptions import ClientError

TELEGRAM_BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
S3_BUCKET = os.environ["S3_BUCKET"]
REGION = os.environ.get("AWS_REGION", "us-east-1")
BEDROCK_MODEL_ID = os.environ["BEDROCK_MODEL_ID"]  

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime", region_name=REGION)

def lambda_handler(event, context):
    print("Received SQS event:", json.dumps(event))

    for record in event.get("Records", []):
        try:
            message_body = json.loads(record["body"])
            chat_id = message_body["chat_id"]
            prompt = message_body.get("user_input", "").strip()

            print(f"Processing chat_id={chat_id}, prompt='{prompt}'")

            if not prompt:
                send_telegram_message(chat_id, "Please send a description for the image you want me to generate.")
                continue

            image_bytes = generate_image_from_bedrock(prompt)
            
            if not image_bytes:
                send_telegram_message(chat_id, "Sorry, I couldn’t generate your image. Please try again later.")
                continue

            image_key = upload_image_to_s3(image_bytes)

            image_url = create_presigned_url(S3_BUCKET, image_key)

            send_telegram_message(chat_id, f"🎨 Here’s your generated image:\n{image_url}")

            print(f"✅ Completed successfully for chat_id {chat_id}")

        except Exception as e:
            print(f"❌ Error processing record: {str(e)}", flush=True)
            raise e

    return {"statusCode": 200, "body": json.dumps({"ok": True})}



def generate_image_from_bedrock(prompt: str) -> bytes:

    print(f"Generating image for prompt: {prompt}")

    body = {
        "taskType": "TEXT_IMAGE",
        "textToImageParams": {"text": prompt},
        "imageGenerationConfig": {
            "numberOfImages": 1,
            "quality": "standard",
            "cfgScale": 8.0,
            "height": 512,
            "width": 512
        }
    }

    try:
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(body),
            contentType="application/json",
            accept="application/json"
        )
    except ClientError as e:
        print("❌ Bedrock error:", e)
        return None

    model_output = json.loads(response["body"].read())

    image_base64 = model_output.get("images", [None])[0]
    if not image_base64:
        print("⚠️ No image found in response:", model_output)
        return None

    image_bytes = base64.b64decode(image_base64)
    print(f"Image generated, size = {len(image_bytes)} bytes")
    return image_bytes


def upload_image_to_s3(image_bytes: bytes) -> str:

    key = f"generated/{uuid.uuid4().hex}.png"
    print(f"Uploading image to s3://{S3_BUCKET}/{key}")

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=image_bytes,
        ContentType="image/png"
    )

    print(f"✅ Uploaded to S3 key: {key}")
    return key


def create_presigned_url(bucket_name: str, object_key: str, expiration: int = 3600) -> str:
    """
    Creates a presigned URL to view/download the image.
    """
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket_name, "Key": object_key},
            ExpiresIn=expiration
        )
        print(f"Presigned URL created: {url}")
        return url
    except ClientError as e:
        print("❌ Error generating presigned URL:", e)
        return "Error creating URL."


def send_telegram_message(chat_id: int, text: str):
    """
    Sends a plain text message back to the user via Telegram.
    """
    print(f"Sending message to Telegram chat_id={chat_id}: {text}")
    api_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    resp = requests.post(api_url, json={"chat_id": chat_id, "text": text})
    if not resp.ok:
        print("⚠️ Telegram send error:", resp.status_code, resp.text)
