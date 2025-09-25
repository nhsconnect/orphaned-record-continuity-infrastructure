#!/bin/bash
if [ "$1" == "" ]; then
  echo please pass week ending date as first parameter
  exit 1
fi
if [ "$NHS_ENVIRONMENT" == "" ]; then
  echo please ensure NHS_ENVIRONMENT variable is set
  exit 1
fi

export WEEK_ENDING=$1
ENVIRONMENT=$NHS_ENVIRONMENT

export COUNT_ACCOUNT=$(aws sts get-caller-identity | jq -r .'Account')

echo getting counts for week ending $WEEK_ENDING from environment $ENVIRONMENT account no $COUNT_ACCOUNT

export END_TIME=$(python -c "import datetime; d = datetime.datetime.fromisoformat('$WEEK_ENDING'); print(int(d.timestamp()))")
export START_TIME=$(python -c "import datetime; d = datetime.datetime.fromisoformat('$WEEK_ENDING') - datetime.timedelta(days=7); print(int(d.timestamp()))")

echo

function calculate_total_for_week() {

  export QUERY="fields @timestamp, message, bin(1d) as day | filter message like /$MESSAGE_FILTER/ | stats count(message) by day | sort by day"
  export LOG_GROUP=/nhs/deductions/$ENVIRONMENT-$COUNT_ACCOUNT/$LOG_SERVICE_NAME

  echo count type is $COUNT_TYPE, log group is $LOG_GROUP, query is
  echo '>>>'
  echo $QUERY
  echo '<<<'

  export QUERY_START_RESPONSE=$(aws logs start-query --log-group-name $LOG_GROUP --query-string "$QUERY" --end-time $END_TIME --start-time $START_TIME)

  export QUERY_ID=$(echo $QUERY_START_RESPONSE | jq -r '.queryId')
  echo query id is $QUERY_ID

  until [ $(aws logs get-query-results --query-id $QUERY_ID  | jq -r '.status') == 'Complete' ]
  do
    echo Query not yet complete
    sleep 1
  done

  export QUERY_RESULTS=$(aws logs get-query-results --query-id $QUERY_ID)

  export DAY_COUNTS=$(echo $QUERY_RESULTS | jq  '[.results[] | .[1].value | tonumber]')
  export DAY_DATES=$(echo $QUERY_RESULTS | jq  '[.results[] | .[0].value]')
  echo counts each day: $DAY_COUNTS
  echo day dates being: $DAY_DATES

  export QUERY_TOTAL=$(echo $DAY_COUNTS | jq 'add')
  echo '**'
  echo "** total $COUNT_TYPE for week:" $QUERY_TOTAL
  echo '**'
}

export LOG_SERVICE_NAME=suspension-service

export MESSAGE_FILTER="(?i)mof-updated"
export COUNT_TYPE='MOF updates'
calculate_total_for_week

export LOG_SERVICE_NAME=re-registration-service

export MESSAGE_FILTER="Re-registration event received for suspended patient. From"
export COUNT_TYPE='re-registrations'
calculate_total_for_week

export MESSAGE_FILTER="Patient has been re-registered at a different GP practice, or at the same GP practice more than 3 days later"
export COUNT_TYPE='non-anomalies'
calculate_total_for_week
