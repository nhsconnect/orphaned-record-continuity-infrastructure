import logging
import os
import re
import time
import traceback
from datetime import date, datetime
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from enum import Enum

import boto3
import botocore
from botocore.exceptions import ClientError
from dateutil.relativedelta import relativedelta

from configuration import Configuration

logger = logging.getLogger()
logger.setLevel(logging.INFO)
tempPath = '/tmp'
config = Configuration("cost-report-configuration.yml")


def get_formatted_report_date():
    report_date = resolve_report_date(config.get_generate_report_for_year(),
                                      config.get_generate_report_for_month())
    formatted_date = datetime(report_date['year'], report_date['month'], 1).strftime("%b-%Y")
    return formatted_date


def get_cost_report_file_name():
    return f'{get_formatted_report_date()}-{config.get_environment()}-{config.get_account_id()}-aws-cost-and-usage-report.csv'


def get_subject():
    subject = f'{get_formatted_report_date()}-{config.get_environment()} PRM Cost and Usage Report'
    return subject


def get_body_text():
    current_date = (date.today()).strftime('%Y-%m-%d')
    email_body = f"Hi, \n" \
                 f"Please find attached cost and usage report. \n\n" \
                 f"This report was generated on : {current_date}\n" \
                 f"For the month of : {get_formatted_report_date()}\n\n" \
                 f"Regards, \n" \
                 f"PRM Team"
    return email_body


class AthenaQueryExecutionStatus(str, Enum):
    QUEUED = 'QUEUED'
    RUNNING = 'RUNNING'
    SUCCEEDED = 'SUCCEEDED'
    FAILED = 'FAILED'
    CANCELLED = 'CANCELLED'


class Clock:
    def date_now(self):
        return date.today()


def resolve_report_date(year, month, clock=Clock()):
    if year or month:
        try:
            specified_date = datetime.strptime(f"{year}-{month}", '%Y-%m')
            return {"year": specified_date.year, "month": specified_date.month}
        except ValueError:
            raise ValueError(f"Incorrect date format {year}-{month}, should be YYYY-MM")
    else:
        date_now = clock.date_now()
        report_date = date_now - relativedelta(months=1)
        return {"year": report_date.year, "month": report_date.month}


def populate_query_parameters(query, substitutions):
    substrings = sorted(substitutions, key=len, reverse=True)
    regex = re.compile('|'.join(map(re.escape, substrings)))
    return regex.sub(lambda match: substitutions[match.group(0)], query)


def get_var_char_values(d):
    rowList = []
    for obj in d['Data']:
        if obj.get('VarCharValue'):
            rowList.append(obj['VarCharValue'])
        else:
            rowList.append("")
    return rowList


def execute_cur_queries_on_athena():
    queries_to_execute = get_queries_to_execute()
    client = boto3.client('athena', region_name=config.get_region())
    logger.info("Starting CUR query execution ... ")
    wait_for_query_execution_seconds = 5
    query_execution_duration = 60  # 5 minutes
    query_ids = []

    for query_index in range(len(queries_to_execute)):
        resp = client.start_query_execution(
            QueryString=queries_to_execute[query_index]['queryString'],
            ResultConfiguration={
                'OutputLocation': config.get_report_output_location()
            })
        query_id = resp['QueryExecutionId']
        query_ids.append(query_id)
        logger.info(
            "Query to execute is: " + queries_to_execute[query_index]['queryString'] + " QueryId is: " + query_id)

        while query_execution_duration > 0:
            query_execution_duration = query_execution_duration - 1
            response_get_query_details = client.get_query_execution(
                QueryExecutionId=resp['QueryExecutionId']
            )
            status = response_get_query_details['QueryExecution']['Status']['State']
            if (status == AthenaQueryExecutionStatus.FAILED) or (status == AthenaQueryExecutionStatus.CANCELLED):
                failure_reason = response_get_query_details['QueryExecution']['Status']['StateChangeReason']
                logger.error("Query either FAILED or CANCELED, reason is: " + failure_reason, exc_info=True)
                raise Exception("Athena query either FAILED or CANCELED with reason " + failure_reason)

            elif status == AthenaQueryExecutionStatus.QUEUED:
                logger.info('Query queued, waiting for query execution to begin')
                time.sleep(wait_for_query_execution_seconds)
                continue

            elif status == AthenaQueryExecutionStatus.SUCCEEDED:
                logger.info("Query execution succeeded, the query ID is: " + resp['QueryExecutionId'])
                location = response_get_query_details['QueryExecution']['ResultConfiguration']['OutputLocation']

                response_query_result = client.get_query_results(
                    QueryExecutionId=resp['QueryExecutionId']
                )
                if len(response_query_result['ResultSet']['Rows']) > 1:
                    logger.info("Query generated results at location: " + location)
                else:
                    logger.info("Query did not generate any results")
                break

    return query_ids


def get_queries_to_execute():
    queries_to_execute = []
    report_date = resolve_report_date(config.get_generate_report_for_year(),
                                      config.get_generate_report_for_month())
    query_parameters = {
        'CUR_DB': config.get_glue_db(),
        'CUR_TABLE': config.get_glue_table(),
        'CUR_YEAR': str(report_date['year']),
        'CUR_MONTH': str(report_date['month'])
    }
    athena_queries = config.get_athena_queries()
    for index in range(len(athena_queries)):
        query = populate_query_parameters(list(athena_queries[index].values())[0], query_parameters)
        queries_to_execute.append({'name': list(athena_queries[index].keys())[0], 'queryString': query})
    return queries_to_execute


def fetch_cost_report_into_lambda_directory(query_ids):
    # Target bucket and key for CUR query results in s3
    cur_bucket = config.get_report_output_location().split('//')[1].split('/')[0]
    cur_key_path = config.get_report_output_location().split('//')[1].lstrip(cur_bucket).lstrip('/')
    os.chdir(tempPath)
    s3 = boto3.resource('s3')
    for i in range(len(query_ids)):
        logger.info(
            "Copying query result from output source location: s3://" + cur_bucket + "/" + cur_key_path + query_ids[
                i] + ".csv")
        try:
            s3.Bucket(cur_bucket).download_file(cur_key_path + query_ids[i] + '.csv', get_cost_report_file_name())
            is_file_downloaded = os.path.isfile('/tmp/' + get_cost_report_file_name())
            logger.info(f"Successfully copied the report:  {is_file_downloaded}")
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "404":
                logger.error("The target query result file does not exist.", exc_info=True)
                raise e
            else:
                logger.error("Unexpected error while fetching cost report into Lambda directory.", exc_info=True)
                raise e


def get_ssm_parameter(parameter_name):
    client = boto3.client('ssm', region_name=config.get_region())
    return client.get_parameter(
        Name=parameter_name
    )


def send_error_details_to_support(error_message):
    sender_email = get_ssm_parameter(config.get_sender_email_ssm_parameter())['Parameter']['Value']
    support_email_address = get_ssm_parameter(config.get_support_email_ssm_parameter())['Parameter']['Value']

    email_body = f"Hi, \n" \
                 f"There was an error generating the cost and usage report. Please find details below: \n\n" \
                 f"Error description: \n{error_message}\n\n" \
                 f"Error stack trace:\n" \
                 f"{traceback.format_exc()} \n\n" \
                 f"Regards, \n" \
                 f"PRM Team"
    send_email("Error generating PRM cost and usage report", sender_email, support_email_address, None, email_body)


def send_email(email_subject, email_sender, email_receivers, report_name, email_body):
    logger.info("Sending email via SES")
    os.chdir(tempPath)
    client = boto3.client('ses', region_name=config.get_region())
    message = MIMEMultipart('mixed')
    message['Subject'] = email_subject
    message['From'] = email_sender
    message['To'] = email_receivers
    message.attach(MIMEText(email_body))
    if report_name:
        email_attachment = MIMEApplication(open(report_name, 'rb').read())
        email_attachment.add_header('Content-Disposition', 'attachment', filename=os.path.basename(report_name))
        message.attach(email_attachment)
    try:
        response = client.send_raw_email(
            Source=email_sender,
            Destinations=email_receivers.split(','),
            RawMessage={
                'Data': message.as_string()
            }
        )
        return response
    except ClientError as e:
        logger.error(e.response['Error']['Message'], exc_info=True)


def lambda_handler(event, context):
    try:
        query_ids = execute_cur_queries_on_athena()
        fetch_cost_report_into_lambda_directory(query_ids)
    except Exception as e:
        send_error_details_to_support("Unexpected exception while generating cost and usage report. \n" + str(e))
    else:
        sender_email = get_ssm_parameter(config.get_sender_email_ssm_parameter())['Parameter']['Value']
        recipient_emails = get_ssm_parameter(config.get_recipient_email_ssm_parameter())['Parameter']['Value']
        response = send_email(get_subject(), sender_email, recipient_emails, get_cost_report_file_name(),
                              get_body_text())
        return response
