# Datadog Terraform

## State
Terraform must store state about your managed infrastructure and configuration. 
This state is used by Terraform to map real world resources to your configuration, 
keep track of metadata, and to improve performance for large infrastructures.

This bucket should be configured only on OPS account.

Create S3 bucket for storing the terraform state:
```
hf-stack-deploy -p cloudformation@husdyrfag-ops -f metrics-logs/datadog/terraform/s3/husdyrfag-ops.json
```

## User
Terrafrom needs a user to access s3 bucket to read and persist state.

Create user:
```
hf-stack-deploy -p cloudformation@husdyrfag-ops -y -f metrics-logs/datadog/terraform/iam/husdyrfag-ops.json
```

Create access key for the user:
```
aws iam create-access-key --user-name DatadogTerraform --profile cloudformation@husdyrfag-ops
```

## Export configuration
Configure your [AWS access keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) as 
environment variables:
```
export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

## To test your changes use commands below. Refer to [terrafrom docs](https://www.terraform.io/docs/commands/init.html) for more details

#### Initialize a Terraform working directory
```
terraform init \
  -var datadog_api_key=(your Datadog api key) \
  -var datadog_app_key=(your Datadog application key)
```

#### Generate and show an execution plan
```
terraform plan \
  -var datadog_api_key=(your Datadog api key) \
  -var datadog_app_key=(your Datadog application key)
```

## CI

All changes to the Datadog account should be applied by Concourse CI. It checks
for any changes and applies them using hashicorp/terraform docker image. Please
refer to [concourse job configuration](./ci/terraform.yml) for more details.

To deploy the concourse pipeline use:

```
fly -t husdyrfag set-pipeline \
    -p datadog-terraform \
    -c ci/terraform.yml
```

Note: credentials are stored in
[Credhub](https://github.com/TINE-SA/tine-cloud-pipelines#credhub) under the prefix
`/concourse/husdyrfag/datadog-terraform`.
