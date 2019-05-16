# Concourse setup

Concourse is "mostly" installed via
[concourse-up](https://github.com/EngineerBetter/concourse-up), however, due to
no extension point for AWS provisioned SSL certificates, there are some
additional moving parts to get that in place.

## IAM user concourse-up

Template that creates the concourse-up user.

```
hf-stack-deploy -p cloudformation@husdyrfag -f ops/concourse/user.json
```

After running the template, create the access keys.

```
aws iam create-access-key \
    --profile cloudformation@husdyrfag-ops \
    --cli-input-json '{"UserName": "concourse-up"}'
```

## Concourse-up

Concourse is installed with [concourse-up](https://github.com/EngineerBetter/concourse-up). Download the latest version,
make it executable and put it on `$PATH`, so it can be executed with `concourse-up`.

You need [envchain](https://github.com/sorah/envchain) to set the AWS
environment variables.

To install Concourse:

```sh
envchain -s concourseup AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
 ->  <enter id and key when prompted>

envchain concourseup concourse-up deploy husdyrfag
```

Note output from this will give you a command to log in to concourse. It will look like this.

```
DEPLOY SUCCESSFUL. Log in with:
fly --target husdyrfag login --insecure --concourse-url https://52.211.71.162 --username admin --password <password>
```

Then resize the worker size with:

```sh
envchain concourseup concourse-up deploy --worker-size large --workers 1 husdyrfag
```

Configure the domain:

```sh
envchain concourseup concourse-up deploy --worker-size large --workers 1 --domain ci.husdyrfag-ops.io husdyrfag
```

Use `concourse-up help deploy` for more info.

<a id="concourse-ssl"></a>
### Certificate for Concourse

Due to [this issue](https://github.com/EngineerBetter/concourse-up/issues/24),
we had to created an ALB for handle the certificate and then delete the A record
that concourse-up creates.

To delete the A record, first open
`husdyrfag/concourse/delete-concourse-A-record.json` and make sure that TTL and
the IP address matches the
[actual route53 record set](https://console.aws.amazon.com/route53/home#resource-record-sets:Z58RR2DZCLLEA).
Then run:

```sh
aws route53 change-resource-record-sets \
    --hosted-zone-id Z3BQPKHD2G863L \
    --change-batch file://ops/concourse/delete-concourse-A-record.json \
    --profile cloudformation@husdyrfag-ops
```

Now open `husdyrfag/concourse/concourse.json` and verify that the `InstanceId`
parameter holds the right value (should be the instance id of the concourse
instance).

If the CloudFormation stacks are already up, clear the load balancer and routing
stack first:

```sh
hf-stack-delete -p cloudformation@husdyrfag-ops -f ops/concourse/concourse.json
```

Deploy the CloudFormation stack:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-ops -f ops/concourse/concourse.json
```

Set up team and authorization with GitHub OAuth. Client Id, and secret can be found in 
[confluence](https://confluence.tine.no/display/TDOC/Concourse+App+i+GitHub).
```bash
fly -t husdyrfag \
    set-team -n husdyrfag \
    --github-auth-client-id <client_id> \
    --github-auth-client-secret <secret> \
    --github-auth-team TINE-SA/developers
```

<a id="rotate-keys"></a>
## Rotate Concourse Keys

The `ConcourseWorker` has access keys in the ops/dev/staging/prod accounts that
are used by the Concourse pipelines. These keys are stored in Credhub, as
[described in the Tine cloud pipelines repo](https://github.com/TINE-SA/tine-cloud-pipelines#credhub).
Access keys should be rotated routinely, and this can be done using the
`rotate-keys.sh` script. It will read the current keys out of Credhub and use
them to generate new ones, update Credhub, and delete the old ones. To run this
script you need to already be logged into Credhub (see linked documentation).

```sh
./ops/concourse/ci/rotate-keys.sh
```

<a id="rotate-keys-pipeline"></a>
### Concourse pipeline for rotating ConcourseWorker keys periodically

To automatically  rotate keys for `ConcourseWorker` there is a
Concourse pipeline that runs periodically. To be able to use credhub
cli, a custom docker container has been created and uploaded to ECR. This container
can be updated by issuing the following:

```bash
$(aws ecr get-login --no-include-email --profile cloudformation@husdyrfag-ops)
docker build -t 067191250127.dkr.ecr.eu-west-1.amazonaws.com/husdyrfag/concourse-rotate-keys .
docker push 067191250127.dkr.ecr.eu-west-1.amazonaws.com/husdyrfag/concourse-rotate-keys
```

To create or update the pipeline
```bash
fly -t husdyrfag set-pipeline -p rotate-concourse-keys -c ci/pipeline.yml
```
