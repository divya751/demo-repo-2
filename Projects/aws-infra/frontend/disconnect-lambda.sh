#!/bin/bash

eval $(hf-getopt "$@")

distribution_id=$(echo "$configuration" | jq -cr ".parameters.FrontendCDN")

echo "CloudFront distribution: $distribution_id"

config='{"Quantity": 0}'

distribution=$(aws cloudfront get-distribution $aws_args --id "$distribution_id")
updated=$(echo "$distribution" |
              jq ".Distribution.DistributionConfig" |
              jq ".DefaultCacheBehavior.LambdaFunctionAssociations = $config")
etag=$(echo "$distribution" | jq -cr ".ETag")

aws cloudfront update-distribution $aws_args \
    --if-match "$etag" \
    --id "$distribution_id" \
    --distribution-config "$updated"
