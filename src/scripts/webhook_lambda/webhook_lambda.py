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
        body = json.loads(event.get("body", "{}"))

        print("Received Telegram Update:", json.dumps(body))

        # Telegram updates can vary (message, callback_query, etc.)
        chat_id = None
        user_input = None

        if "message" in body:
            chat_id = body["message"]["chat"]["id"]
            user_input = body["message"].get("text", "")
        elif "callback_query" in body:
            chat_id = body["callback_query"]["message"]["chat"]["id"]
            user_input = body["callback_query"].get("data", "")

        if chat_id is None:
            raise ValueError("No chat_id found in update")

        # Construct payload for worker Lambda
        payload = {
            "chat_id": chat_id,
            "user_input": user_input,
            "raw_update": body  # keep raw update in case worker needs extra data
        }

        # Push to SQS
        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(payload)
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"ok": True})
        }

    except Exception as e:
        print("Error:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
