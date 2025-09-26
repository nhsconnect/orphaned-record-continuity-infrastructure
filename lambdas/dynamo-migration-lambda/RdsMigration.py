# TODO: PRMT-4648 - THIS IS A ONE-TIME MIGRATION SCRIPT LAMBDA. DELETE THIS .PY FILE AFTER USAGE!
import os
from typing import Optional

import boto3
import logging
import datetime
import psycopg2

from enum import Enum
from dateutil import parser
from zoneinfo import ZoneInfo
from dataclasses import dataclass

AWS_REGION = 'eu-west-2'
TARGET_ENVIRONMENT = os.environ["ENVIRONMENT_NAME"]
NEW_TABLE_NAME = f'{TARGET_ENVIRONMENT}-ehr-transfer-tracker'

ssm_client = boto3.client("ssm")
dynamo_client = boto3.client("dynamodb", region_name=AWS_REGION)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

conversations_to_delete = {}

class MessageRowItem(Enum):
    INBOUND_CONVERSATION_ID = 0
    LAYER = 1
    INBOUND_MESSAGE_ID = 2
    CREATED_AT = 3
    UPDATED_AT = 4
    DELETED_AT = 5
    PARENT_ID = 6


@dataclass
class DatabaseCredentials:
    user: str
    password: str
    host: str
    database: str


def _get_new_datetime(old_datetime: datetime) -> Optional[str]:
    if old_datetime is not None:
        target_timezone = ZoneInfo('Europe/London')
        formatted_datetime = str(old_datetime).split('.')[0]
        parsed_datetime = parser.parse(formatted_datetime).astimezone(target_timezone).isoformat()

        return str(parsed_datetime)


def _fetch_ssm_parameter(name: str, decrypt: bool = False) -> str:
    return ssm_client.get_parameter(Name=name, WithDecryption=decrypt)['Parameter']['Value']


def _get_rds_credentials() -> DatabaseCredentials:
    credentials = {
        "host": _fetch_ssm_parameter(f'/repo/{TARGET_ENVIRONMENT}/output/prm-deductions-ehr-repository/db-host'),
        "user": _fetch_ssm_parameter(f'/repo/{TARGET_ENVIRONMENT}/user-input/ehr-repo-db-username', True),
        "password": _fetch_ssm_parameter(f'/repo/{TARGET_ENVIRONMENT}/user-input/ehr-repo-db-password', True),
        "database": _fetch_ssm_parameter(f'/repo/{TARGET_ENVIRONMENT}/output/prm-deductions-ehr-repository/db-name', True)
    }

    return DatabaseCredentials(**credentials)


def _get_core_and_fragments(connection) -> list[tuple]:
    logger.info("Fetching CORE/FRAGMENT(s) from RDS.")

    with connection.cursor() as cursor:
        statement = """
        SELECT
            upper(conversation_id::text) AS InboundConversationId,
            CASE
              WHEN type = 'ehrExtract' THEN 'CORE'
              ELSE concat('FRAGMENT#', upper(message_id::text))
            END AS Layer,
            upper(message_id::text) AS InboundMessageId,
            created_at AS CreatedAt,
            updated_at AS UpdatedAt,
            deleted_at AS DeletedAt,
            upper(parent_id::text) AS ParentId
        FROM messages;
        """

        cursor.execute(statement)
        result = cursor.fetchall()

        logger.info(f"Found {len(result)} records when querying the RDS database.")
        return result


def _get_dynamo_items(rds_result_set: list[tuple]) -> list[dict]:
    logger.info(f"Constructing DynamoDB items from RDS result set.")
    dynamo_items = []

    for row in rds_result_set:
        inbound_conversation_id = row[MessageRowItem.INBOUND_CONVERSATION_ID.value]
        inbound_message_id = row[MessageRowItem.INBOUND_MESSAGE_ID.value]
        layer = row[MessageRowItem.LAYER.value]
        created_at = _get_new_datetime(row[MessageRowItem.CREATED_AT.value])
        updated_at = _get_new_datetime(row[MessageRowItem.UPDATED_AT.value])

        item = {
            'InboundConversationId': {'S': inbound_conversation_id},
            'InboundMessageId': {'S': inbound_message_id},
            'TransferStatus': {'S': 'INBOUND_COMPLETE'},
            'Layer': {'S': layer},
            'CreatedAt': {'S': created_at},
            'ReceivedAt': {'S': created_at}, # Passed created_at as it's the same
            'UpdatedAt': {'S': updated_at},
        }

        if row[MessageRowItem.DELETED_AT.value] is not None:
            deleted_at = str(int(row[MessageRowItem.DELETED_AT.value].timestamp()))
            item['DeletedAt'] = {'N': deleted_at}

            if layer == "CORE":
                conversations_to_delete[inbound_conversation_id] = deleted_at

        if row[MessageRowItem.PARENT_ID.value] is not None:
            item['ParentId'] = {'S': row[MessageRowItem.PARENT_ID.value]}

        dynamo_items.append(item)

    return dynamo_items


def _persist_to_dynamo(items: list[dict]) -> None:
    for item in items:
        dynamo_client.put_item(
            TableName=NEW_TABLE_NAME,
            Item=item
        )


def _migrate_rds() -> dict:
    logger.info("Beginning RDS migration...")
    credentials = _get_rds_credentials()
    rds_connection = psycopg2.connect(
        user=credentials.user,
        password=credentials.password,
        host=credentials.host,
        database=credentials.database
    )

    with rds_connection as connection:
        result = _get_core_and_fragments(connection)
        dynamo_items = _get_dynamo_items(result)
        result = None # To lower memory
        _persist_to_dynamo(dynamo_items)
        dynamo_items = None # To lower memory

    return conversations_to_delete