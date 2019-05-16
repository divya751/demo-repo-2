#!/bin/bash

set -e

if [ ! -z "$credhub_password" ]; then
  export CREDHUB_CLIENT=credhub_cli
  export CREDHUB_SERVER="${credhub_server}"
  export CREDHUB_SECRET="${credhub_password}"
  export CREDHUB_CA_CERT="${credhub_certificate}"
  credhub login

    if [ $? -ne 0 ]; then
        echo "Failed to login to credhub, aborting"
        exit 1
    fi
fi

backup_date=$(date +%Y-%m-%dT%H:%M:%S%z)
backup_file="credhub_backup_$(date +%Y%m%d%H%M%S).json"
backup_json='{"credhub_credentials": []}'
backup_json=$(echo $backup_json | jq --arg backup_date $backup_date '. + {date: $backup_date}')

credhub_credentials=$(credhub find --output-json | jq -cr '.credentials')

for row in $(echo "${credhub_credentials}" | jq -cr '.[]'); do
  name=$(echo $row | jq -cr '.name')
  echo "${name}"
  credential=$(credhub get --output-json --name="${name}" | jq -cr '.')
  backup_json=$(echo $backup_json | jq '.credhub_credentials += ['"${credential}"']')
done

echo "${backup_json}" > ${backup_file}
