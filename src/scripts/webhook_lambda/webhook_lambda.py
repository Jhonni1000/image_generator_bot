import json
import os
import boto3

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]

def lambda_handler(event, context):
    """
    Telegram webhook Lambda.
    Extracts chat_id and message, pushes them into SQS.
    """
    try:
        print("Received event:", event)

        # API Gateway v2 wraps the Telegram payload in a string body
        body = json.loads(event.get("body", "{}"))
        print("Parsed Telegram Update:", json.dumps(body))

        chat_id = None
        user_input = None

        if "message" in body:
            chat = body["message"]["chat"]
            chat_id = chat["id"]
            user_input = body["message"].get("text", "")
        elif "callback_query" in body:
            chat = body["callback_query"]["message"]["chat"]
            chat_id = chat["id"]
            user_input = body["callback_query"].get("data", "")

        if chat_id is None:
            raise ValueError("No chat_id found in update")

        payload = {
            "chat_id": chat_id,
            "user_input": user_input,
            "raw_update": body
        }

        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(payload)
        )
        print(f"Message sent to SQS for chat_id {chat_id}")

        return {
            "statusCode": 200,
            "body": json.dumps({"ok": True})  # always string
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 200,
            "body": json.dumps({"error": str(e)})  # ensure string
        }
