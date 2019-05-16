#!/bin/bash

set -e

export CREDHUB_CLIENT=credhub_cli
export CREDHUB_SERVER=""
export CREDHUB_SECRET=""
export CREDHUB_CA_CERT=""
credhub login

restore_file=$1
restore_file_date=$(cat ${restore_file} | jq -cr '.date')

echo Restoring ${restore_file_date}

credhub_credentials=$(cat $restore_file | jq -cr '.credhub_credentials')

lines=$(echo "${credhub_credentials}" | jq -cr '.[].name' | wc -l)

for i in $(seq 0 $((${lines} - 1))); do
  credential=$(echo "${credhub_credentials}" | jq -cr '.['$i']')
  name=$(echo ${credential} | jq -rc '.name')
  type=$(echo ${credential} | jq -rc '.type')
  echo ${name}
  if [ "$type" == "rsa" ]; then
    public_key=$(echo ${credential} | jq -rc '.value.public_key')
    private_key=$(echo ${credential} | jq -rc '.value.private_key')

    credhub set --name="${name}" --type="${type}" --public="${public_key}" --private="${private_key}"

  elif [ "$type" == "password" ]; then
    value=$(echo ${credential} | jq -rc '.value')
    credhub set --name="${name}" --type="${type}" --password="${value}"
  else
    value=$(echo ${credential} | jq -rc '.value')

    credhub set --name="${name}" --type="${type}" --value="${value}"
  fi
done
