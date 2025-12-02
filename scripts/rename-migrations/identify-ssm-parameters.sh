#!/bin/bash
if [ "$1" == "" ]; then
  echo please pass name to be renamed as first parameter
  exit 1
fi
OLD_NAME=$1

export OLD_NAME
POSSIBLE_PARAMETERS_TO_RENAME=$(aws ssm describe-parameters | jq -r '.Parameters[].Name | select(contains(env.OLD_NAME))')
for param in $POSSIBLE_PARAMETERS_TO_RENAME
do
  echo $param
done