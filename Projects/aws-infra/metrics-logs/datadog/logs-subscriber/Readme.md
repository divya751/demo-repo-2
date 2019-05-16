# Datadog logs subscriber
Lambda function that creates automatically subscription filters to datadog logs lambda function.

Create concourse pipeline in openfarm:
```sh
fly -t openfarm set-pipeline \
    -p logs-subscriber \
    -c ../../../../tine-cloud-pipelines/pipelines/cloudformation.yml \
    -l ci/config.yml
```
or in husdyrfag:
```sh
fly -t husdyrfag set-pipeline \
    -p logs-subscriber \
    -c ../../../../tine-cloud-pipelines/pipelines/cloudformation.yml \
    -l ci/config.yml
```