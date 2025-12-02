#!/bin/bash
if [ "$1" == "" ]; then
  echo please pass existing service name as first parameter
  exit 1
fi
EXISTING_SERVICE_NAME=$1

if [ "$2" == "" ]; then
  echo please pass new service name as second parameter
  exit 2
fi
NEw_SERVICE_NAME=$2

if [ "$NHS_ENVIRONMENT" == "" ]; then
  echo please ensure NHS_ENVIRONMENT is set to current environment
  exit 3
fi

copied_key_name () {
  local original_key=$1
  echo $original_key | sed -e "s/\/${EXISTING_SERVICE_NAME}/\/${NEw_SERVICE_NAME}/g"
}

copy_param () {
  local original_key=$1
  local new_key=$2
  local param_value=$(aws ssm get-parameter --with-decryption --name $original_key | jq -r .Parameter.Value)
  aws ssm put-parameter --type SecureString --name $new_key --value "$param_value"
  local copy_result=$?
  echo copy result is $copy_result
}

ensure_param_copied () {
  local original_key=$1
  local new_key=$(copied_key_name $original_key)
  if [[ "$ALL_KEYS" == *"$new_key"* ]]; then
    echo "key already exists:" $new_key
  else
    echo "should create key:" $new_key
    copy_param $original_key $new_key
  fi
}

export EXISTING_SERVICE_NAME
export NEw_SERVICE_NAME
export NHS_ENVIRONMENT

echo xxx copying manual input parameters

MANUAL_PARAM_KEYS=$(aws ssm describe-parameters | jq -r '.Parameters[].Name | select(contains("/repo/" + env.NHS_ENVIRONMENT + "/user-input/" + env.EXISTING_SERVICE_NAME))')
for manual_param_key in $MANUAL_PARAM_KEYS
do
  ensure_param_copied $manual_param_key
done

echo xxx copying service and user api keys

ALL_KEYS=$(aws ssm describe-parameters | jq -r '.Parameters[].Name | select(contains("/repo/" + env.NHS_ENVIRONMENT + "/user-input/api-keys/"))')
export ALL_KEYS
EXISTING_SERVICE_NAME_KEYS=$(echo $ALL_KEYS | xargs -n 1 | grep $EXISTING_SERVICE_NAME)

for existing_service_name_key in $EXISTING_SERVICE_NAME_KEYS
do
  ensure_param_copied $existing_service_name_key
done

echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo now manually update service-api-keys in ssm to copy existing entries to new name
echo otherwise key generation will remove new name keys when next runs
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX