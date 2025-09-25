# TODO: PRMT-4648 - THIS IS A ONE-TIME MIGRATION SCRIPT LAMBDA. DELETE THIS .PY FILE AFTER USAGE!

import re
import os
import boto3
import botocore
import logging

from dateutil import parser
from zoneinfo import ZoneInfo
from typing import Optional
from dataclasses import dataclass, asdict, field
from app.RdsMigration import _migrate_rds

OLD_TABLE_NAME = os.environ["OLD_TABLE_NAME"]
NEW_TABLE_NAME = os.environ["NEW_TABLE_NAME"]

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

dynamo_client = boto3.client("dynamodb", region_name="eu-west-2")

status_code_to_reason = {
    "06": "Patient not at surgery.",
    "07": "GP2GP Messaging is not enabled on this system.",
    "09": "EHR Extract received without corresponding request.",
    "10": "Failed to successfully generate EHR Extract.",
    "11": "Failed to successfully integrate EHR Extract.",
    "12": "Duplicate EHR Extract received.",
    "13": "The system’s configuration prevents it from processing this message.",
    "14": "Message not sent because requesting practice is not Large Message compliant",
    "15": "A-B-A EHR Extract Received and Stored As Suppressed Record",
    "17": "A-B-A EHR Extract Received and rejected due to wrong record or wrong patient",
    "18": "Request message not well-formed or not able to be processed",
    "19": "Sender check indicates that Requester is not the patient’s current healthcare provider",
    "20": "Spine system responded with an error",
    "21": "EHR Extract message not well-formed or not able to be processed",
    "23": "Message not sent because sending practice is not Large Message compliant",
    "24": "SDS lookup provided zero or more than one result to the query for each interaction.",
    "25": "Large messages rejected due to timeout duration reached of overall transfer",
    "26": "Returning Patient EHR Extract Received and filed as an attachment",
    "28": "Non A-B-A EHR Extract Received and rejected due to wrong record or wrong patient",
    "29": "Large Message Re-assembly failure",
    "30": "Large Message general failure",
    "31": "The overall EHR Extract has been rejected because one or more attachments via Large Messages were not received.",
    "99": "Unexpected condition."
}

@dataclass
class OldConversation:
    """ Represents the old DynamoDB table structure. """

    # Fields we know will be present.
    conversation_id: str
    nhs_number: str
    source_gp: str
    state: str

    # Fields which may be absent.
    nems_message_id: Optional[str] = field(default=None)
    date_time: Optional[str] = field(default=None)
    created_at: Optional[str] = field(default=None)
    last_updated_at: Optional[str] = field(default=None)

@dataclass
class NewConversation:
    """ Represents the new DynamoDB table structure. """

    # Fields we know will be present.
    inbound_conversation_id: str
    nhs_number: str
    source_gp: str
    transfer_status: str
    layer: str = "CONVERSATION"

    # Fields which may be absent.
    failure_code: Optional[str] = field(default=None)
    failure_reason: Optional[str] = field(default=None)
    nems_message_id: Optional[str] = field(default=None)
    created_at: Optional[str] = field(default=None)
    updated_at: Optional[str] = field(default=None)


def snake_to_pascal(name: str) -> str:
    return ''.join(word.capitalize() for word in name.split('_'))


def _get_new_conversations(old_conversations: list[OldConversation]) -> list[NewConversation]:
    new_conversations = []

    for old_conversation in old_conversations:
        new_conversation = NewConversation(
            inbound_conversation_id=old_conversation.conversation_id.upper(),
            nhs_number=old_conversation.nhs_number,
            source_gp=old_conversation.source_gp,
            transfer_status=_get_new_state(old_conversation.state),
            failure_code=_get_failure_code(old_conversation.state),
            failure_reason=_get_failure_reason(old_conversation.state),
            nems_message_id=old_conversation.nems_message_id,
            created_at=_get_new_datetime(old_conversation.created_at),
            updated_at=_get_new_datetime(old_conversation.last_updated_at)
        )

        if new_conversation.created_at is None and new_conversation.updated_at is None:
            old_datetime = old_conversation.date_time
            new_conversation.created_at = _get_new_datetime(old_datetime)
            new_conversation.updated_at = _get_new_datetime(old_datetime)

        new_conversations.append(new_conversation)

    return new_conversations


def _get_new_state(old_state: str) -> str:
    state_mapping = {
        'EHR_REQUEST_SENT': 'INBOUND_REQUEST_SENT',
        'EHR_TRANSFER_FAILED': 'INBOUND_FAILED',
        'EHR_TRANSFER_TIMEOUT': 'INBOUND_TIMEOUT',
        'EHR_TRANSFER_TO_REPO_COMPLETE': 'INBOUND_COMPLETE',
        'LARGE_EHR_CONTINUE_REQUEST_SENT': 'INBOUND_CONTINUE_REQUEST_SENT',
        'TRANSFER_TO_REPO_STARTED': 'INBOUND_STARTED'
    }

    return state_mapping.get(old_state.split(':')[1])


def _get_failure_code(old_state: str) -> str:
    state_segments = old_state.split(':')
    if len(state_segments) > 2:
        return state_segments[2]

def _get_failure_reason(old_state: str) -> str:
    state_segments = old_state.split(':')
    if len(state_segments) > 2:
        return status_code_to_reason.get(state_segments[2], "<Code not in Specification>")

def _get_new_datetime(old_datetime: str):
    if old_datetime is not None:
        target_timezone = ZoneInfo('Europe/London')
        formatted_datetime = old_datetime.split('.')[0]
        parsed_datetime = parser.parse(formatted_datetime).astimezone(target_timezone).isoformat()

        return parsed_datetime


def _get_old_conversations() -> list[OldConversation]:
    found_conversations = []

    scan_expression = """
    conversation_id, nhs_number, source_gp,
    #transfer_status, nems_message_id, date_time,
    created_at, last_updated_at
    """

    dynamo_paginator = dynamo_client.get_paginator('scan')
    dynamo_response = dynamo_paginator.paginate(
        TableName=OLD_TABLE_NAME,
        Select='SPECIFIC_ATTRIBUTES',
        ProjectionExpression=scan_expression,
        ExpressionAttributeNames={'#transfer_status': 'state'},
        ReturnConsumedCapacity='NONE',
        ConsistentRead=True
    )

    for page in dynamo_response:
        for page_item in page["Items"]:
            found_conversation = OldConversation(**{
                key: value.get('S', value.get('N')) for key, value in page_item.items()
            })

            found_conversations.append(found_conversation)

    return found_conversations


def _persist_new_conversations(new_conversations: list[NewConversation]) -> None:
    for new_conversation in new_conversations:
        dynamo_client.put_item(
            TableName=NEW_TABLE_NAME,
            Item={
                snake_to_pascal(k): {'S': str(v)} for k, v in asdict(new_conversation).items() if v is not None
            }
        )


def _migrate() -> None:
    old_conversations = _get_old_conversations()
    logger.info(f"Found {len(old_conversations)} records in {OLD_TABLE_NAME}.")

    new_conversations = _get_new_conversations(old_conversations)
    old_conversations = None # To lower memory

    _persist_new_conversations(new_conversations)
    new_conversations = None # To lower memory

def _mark_conversations_as_deleted(conversations_to_delete: dict) -> None:
    logger.info(f"Found {len(conversations_to_delete)} conversations to delete...")
    for inbound_conversation_id, deleted_at in conversations_to_delete.items():
        dynamo_client.update_item(
            TableName=NEW_TABLE_NAME,
            Key={
                'InboundConversationId': {'S': inbound_conversation_id},
                'Layer': {'S': 'CONVERSATION'}
            },
            ExpressionAttributeNames={
                '#DA': 'DeletedAt'
            },
            ExpressionAttributeValues={
                ':t': {
                    'N': deleted_at
                }
            },
            UpdateExpression='SET #DA = :t',
            ReturnValues='NONE',
            ReturnConsumedCapacity='NONE'
        )

    logger.info("...Conversations have updated!")

def lambda_handler(event, context) -> dict:
    _migrate()
    conversations_to_delete = _migrate_rds()
    _mark_conversations_as_deleted(conversations_to_delete)

    return {
        "statusCode": 200,
        "body": {
            "status": "success"
        }
    }
