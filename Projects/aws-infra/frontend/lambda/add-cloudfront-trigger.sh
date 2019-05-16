#!/bin/bash

eval $(hf-getopt "$@")

function_name=$(hf-stack-describe "$@" | jq -cr '.Stacks[0].Outputs[]|select(.OutputKey=="LambdaFunctionName").OutputValue')

if [ -z "$function_name" ]; then
    fail 1 "Unable to look up LambdaFunctionName, is the function deployed?"
fi

lambda_arn=$(aws lambda publish-version $aws_args --function-name RewriteUrls | jq -cr '.FunctionArn')
echo "Published lambda version $lambda_arn"

distribution_id=$(echo "$configuration" | jq -cr ".parameters.FrontendCDN")
echo "CloudFront distribution: $distribution_id"

config="{
  \"Quantity\": 1,
  \"Items\": [
    {
      \"LambdaFunctionARN\": \"$lambda_arn\",
      \"EventType\": \"viewer-request\"
    }
  ]
}"

distribution=$(aws cloudfront get-distribution $aws_args --id "$distribution_id")
updated=$(echo "$distribution" |
              jq ".Distribution.DistributionConfig" |
              jq ".DefaultCacheBehavior.LambdaFunctionAssociations = $config")
etag=$(echo "$distribution" | jq -cr ".ETag")

aws cloudfront update-distribution $aws_args \
    --if-match "$etag" \
    --id "$distribution_id" \
    --distribution-config "$updated"
