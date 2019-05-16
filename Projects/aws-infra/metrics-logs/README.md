# Logging

The logging setup consists of three main parts. All CloudTrail logs from the
husdyrfag account are redirected to an S3 bucket in the backup account. A lambda
runs on every update of this bucket and restricts permissions for the husdyrfag
account to `READ` only. The backup bucket is replicated back to a bucket in the
husdyrfag account.

The husdyrfag bucket (AKA replication target) has a lambda associated with it
that triggers on new objects, unzips them and puts them in a Kinesis record. The
Kinesis Firehose delivery stream also has a lambda associated with it to
transform records.

The Kinesis firehose delivers to ElasticSearch, where logs can be viewed from
Kibana.

## Replication target

The replication target setup also includes the Kinesis and Elasticsearch
configuration. It is by far the largest piece of the logging puzzle.

Deploy the stack to the husdyrfag account:

```sh
hf-stack-deploy -p cloudformation@husdyrfag -f logging/replication-target/husdyrfag.json
```

The replication target and log rig runs in the husdyrfag account and not the
sandbox account because there is no chance of accidentally ruining it in the
husdyrfag account (due to the difference in permissions between the two
accounts).

## Backup account

S3 bucket replication requires that the source and target are created in
different regions. For this reason, the backup account uses `eu-central-1` for
its bucket and associated resources.

Deploy the stack to the backup account.

```sh
deploy-stack -p cloudformation@backup -f logging/backup/config.json
```

## Cloudtrail setup

Deploy Cloudtrail the stacks:

```sh
hf-stack-deploy -p cloudformation@sandbox -f logging/cloudtrail/sandbox.json
hf-stack-deploy -p cloudformation@husdyrfag -f logging/cloudtrail/husdyrfag.json
hf-stack-deploy -p cloudformation@master -f logging/cloudtrail/master.json
```

## Datadog setup

### Integration role
Setting up the Datadog integration with Amazon Web Services requires configuring
role delegation using AWS IAM. Integration requires External ID for role
delegation and is unique for each environment. For more information refer to
[setup](https://docs.datadoghq.com/integrations/amazon_web_services/#setup). 
Current configuration sets up [Datadog metrics](https://docs.datadoghq.com/integrations/amazon_web_services/) 
and [Datadog logs](https://docs.datadoghq.com/logs/).

Deploy stack for *DatadogAWSIntegrationRole*:
```
hf-stack-deploy -p cloudformation@husdyrfag-staging -f logging/datadog/integration-role/husdyrfag-dev.json
hf-stack-deploy -p cloudformation@husdyrfag-staging -f logging/datadog/integration-role/husdyrfag-staging.json
hf-stack-deploy -p cloudformation@husdyrfag-staging -f logging/datadog/integration-role/husdyrfag-prod.json
```

### Lambda function
To send logs from S3 and CloudWatch(Lambda) a lambda function that responds to events from S3 and CloudWatch is required. 
Refer to [Datadog logs](./datadog/logs/) for more details and follow instructions to deploy the stack.

### Terraform
All Datadog configuration is managed by [Terrafrom](./datadog/terraform) and deployed automatically by CI/CD.