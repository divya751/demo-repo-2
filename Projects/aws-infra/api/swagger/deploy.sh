#!/bin/bash

eval $(hf-getopt $@)

infra_bucket=$(hf-get-infra-bucket $@)
destination_bucket=$(hf-stack-describe "$@" | jq -r '.Stacks[0].Outputs[]|select(.OutputKey=="BucketName").OutputValue')

swagger_archive=swagger-3_4_2_hf1.zip
version=`echo ${swagger_archive} | sed 's/^.*-\(.*\)\.zip/\1/g'`

pushd $(cd $(dirname "$0") && pwd) > /dev/null

aws s3 cp $aws_args s3://${infra_bucket}/swagger/${swagger_archive} ${swagger_archive}
unzip ${swagger_archive}
cp src/* dist

aws s3 cp $aws_args dist s3://${destination_bucket} --recursive
res=$?
rm -rf dist
rm ${swagger_archive}
popd > /dev/null

if [ $res -eq 0 ]; then
  echo "Swagger UI (${version}) was successfully deployed"
  echo "→ http://${destination_bucket}.s3-website-eu-west-1.amazonaws.com"
else
  echo "Failed to deploy Swagger UI"
  exit 1
fi
