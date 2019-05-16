# Datadog logs
Configuration to push AWS log information to Datadog platform using Lambda function that respond to S3 and CloudWatch 
log events.

Deploy functions using cloud formation template
```sh
hf-stack-deploy -p cloudformation@husdyrfag-dev -f ci/husdyrfag-dev.json
hf-stack-deploy -p cloudformation@husdyrfag-staging -f ci/husdyrfag-staging.json
hf-stack-deploy -p cloudformation@husdyrfag-prod -f ci/husdyrfag-prod.json

hf-stack-deploy -p cloudformation@openfarm-dev -f ci/openfarm-dev.json
hf-stack-deploy -p cloudformation@openfarm-staging -f ci/openfarm-staging.json
hf-stack-deploy -p cloudformation@openfarm-prod -f ci/openfarm-prod.json
```

