#!/bin/sh

set -e

work_dir=`pwd`

echo "Running terraform"
./aws-infra/metrics-logs/datadog/terraform/ci/terraform.sh


echo "Running slack"
cd ${work_dir}
./aws-infra/metrics-logs/datadog/terraform/ci/slack.sh