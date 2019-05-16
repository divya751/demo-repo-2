#!/bin/sh

set -e

cd ./aws-infra/metrics-logs/datadog/terraform/configuration/tinesa-account

terraform init -input=false -var datadog_api_key=$DATADOG_API_KEY -var datadog_app_key=$DATADOG_APP_KEY -var account_alias=$ACCOUNT_ALIAS -backend-config="key=$ACCOUNT_ALIAS"
terraform plan -out=tfplan -input=false -var datadog_api_key=$DATADOG_API_KEY -var datadog_app_key=$DATADOG_APP_KEY -var account_alias=$ACCOUNT_ALIAS
set -x
terraform apply -input=false -auto-approve tfplan