import json
import logging
import os
import re
import uuid

from datetime import datetime, timezone
from typing import List

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs_client = boto3.client("sqs")
s3_client = boto3.client("s3")


class DuplicateNhsNumberException(Exception):
    pass


class InvalidFileFormatException(Exception):
    pass


class InvalidNhsNumberException(Exception):
    pass


class NHSNumberValidator:
    @staticmethod
    def validate(nhs_numbers: str) -> List[str]:
        if not bool(re.match('^[0-9,]+$', nhs_numbers)):
            raise InvalidFileFormatException('File should only contain numbers and commas.')

        nhs_number_list = nhs_numbers.split(',')
        if not all(len(x) == 10 for x in nhs_number_list):
            raise InvalidNhsNumberException('All NHS numbers must be 10 digits long and there must be no trailing commas.')

        if len(nhs_number_list) != len(set(nhs_number_list)):
            raise DuplicateNhsNumberException('Duplicate NHS numbers found.')

        return nhs_number_list


class S3FileReader:
    @staticmethod
    def read(filename, bucket_name) -> str:
        response = s3_client.get_object(Bucket=bucket_name, Key=filename)
        file_lines = response["Body"].readlines()

        if len(file_lines) > 1:
            raise InvalidFileFormatException('All NHS numbers must be contained on a single line, separated by commas.')

        return file_lines[0].decode('utf-8')


def process_nhs_number(nhs_number, previous_ods_code, suspension_queue_url) -> str:
    trace_id = str(uuid.uuid4())
    logger.info(f"Assigned a new traceId: {trace_id}")

    suspension_message_json = json.dumps({
        "nhsNumber": nhs_number,
        "lastUpdated": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "previousOdsCode": previous_ods_code,
        "nemsMessageId": trace_id,
    })

    sqs_client.send_message(
        QueueUrl=suspension_queue_url,
        MessageAttributes={
            "traceId": {
                "DataType": "String",
                "StringValue": trace_id
            }
        },
        MessageBody=suspension_message_json,
    )
    logger.info(f"Sent message for a patient to queue with traceId: {trace_id}")

    return trace_id


def lambda_handler(event, context) -> dict:
    try:
        previous_ods_code = event["previous_ods_code"]
    except KeyError:
        return {"statusCode": 400, "error": "missing attribute 'previous_ods_code'"}

    file_to_ingest = os.environ["INGEST_FILE_NAME"]
    ingestion_bucket_name = os.environ["S3_BUCKET_NAME"]
    suspension_queue_url = os.environ["SUSPENSION_QUEUE_URL"]

    nhs_numbers = S3FileReader.read(filename=file_to_ingest, bucket_name=ingestion_bucket_name)
    nhs_number_list = NHSNumberValidator.validate(nhs_numbers)

    all_trace_ids = [process_nhs_number(nhs_number, previous_ods_code, suspension_queue_url) for nhs_number in nhs_number_list]

    logger.info("Here are all the trace ids that related to this ingest:")
    logger.info(str(all_trace_ids))

    return {"statusCode": 200, "body": str(all_trace_ids)}
