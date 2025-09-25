import urllib3
import boto3
import json
import os

http = urllib3.PoolManager()

class SsmSecretManager:
    def __init__(self, ssm):
        self._ssm = ssm

    def get_secret(self, name):
        response = self._ssm.get_parameter(Name=name, WithDecryption=True)
        return response["Parameter"]["Value"]

def generate_markdown_message(sns_message):
    alarm_name = sns_message['AlarmName']
    state = sns_message['NewStateValue']
    message = sns_message['NewStateReason']
    return f"## **{alarm_name}**\n\nAlarm state: **{state}**\n\n{message}"

def lambda_handler(event, context):
    ssm = boto3.client("ssm")
    secret_manager = SsmSecretManager(ssm)
    alarm_webhook_url = secret_manager.get_secret(os.environ["ALARM_WEBHOOK_URL_PARAM_NAME"])
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])

    ok_state = "OK"
    insufficient_data_state = "INSUFFICIENT_DATA"
    if sns_message['OldStateValue'] == insufficient_data_state and sns_message['NewStateValue'] == ok_state:
        print("Transitioning from INSUFFICIENT_DATA to OK, no need to send notification")
        return

    msg = {
        "text": generate_markdown_message(sns_message),
        "textFormat": "markdown"
    }

    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST', url=alarm_webhook_url, body=encoded_msg)

    print({
        "message": msg["text"],
        "status_code": resp.status,
        "response": resp.data
    })