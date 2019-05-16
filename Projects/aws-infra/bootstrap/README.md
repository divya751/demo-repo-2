# Account bootstrap

To bootstrap a new account, you need to install
[the AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and the
[AWS tooling](https://github.com/TINE-SA/aws-tooling).

To create the account, see [description for how to add an account to the AWS organization](../master/README.md).
After the account is created, proceed with the following manual steps:

1. Change/set the root account password. This must be done in the console. Enter
   an email address and click "reset password". You will recieve an email.
2. Assume the `OrganizationAccountAccessRole` ([See docs](https://aws.amazon.com/blogs/security/how-to-use-aws-organizations-to-automate-end-to-end-account-creation/)):

    ```sh
    aws sts assume-role \
        --role-arn arn:aws:iam::119826691357:role/OrganizationAccountAccessRole
        --role-session-name orgAdminAtHusdyrfagStaging --profile admin@tinesa
    ```

3. Configure a profile for `OrganizationAccountAccessRole` in .aws config files,
   e.g `OrganizationAccountAccessRole@hfstaging`, set the region to `eu-west-1`.
4. Add `aws_access_key_id`, `aws_secret_access_key` and `aws_session_token` to
   this new profile
5. Set the account alias:

    ```sh
    aws iam create-account-alias \
        --account-alias husdyrfag-staging \
        --profile OrganizationAccountAccessRole@hfstaging
    ```

6. Manually register an MFA hardware device on the root account
7. Manually update **Security Token Service Regions** in IAM/Account settings.
   Deactivate all but US East, Ireland and Frankfurt. See
   [docs](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html?icmpid=docs_iam_console).

<a id="password-policy"></a>
## IAM password policy

Set the password policy for the account:

```sh
./bootstrap/iam/set-password-policy.sh \
    -f bootstrap/iam/password-policy-config.json \
    -p OrganizationAccountAccessRole@hfstaging
```

<a id="cloudformation-role"></a>
## Cloudformation role

The CloudFormation role enables further use of CloudFormation to provision
resources:

```sh
hf-stack-deploy \
    -s \
    -f bootstrap/iam/roles/cloudformation.json \
    -p OrganizationAccountAccessRole@hfstaging
```

After you have done this, you should delete the "accountbootstrap" user. From
now on, you should use the `cloudformation@husdyrfag` profile for all resources
you provision in the Husdyrdag account.

Now configure profile "cloudformation@<account>" in `.aws/config` to assume the
Cloudformation role, and set the region to `eu-west-1`:

```
[profile cloudformation@husdyrfag-dev]
role_arn = arn:aws:iam::ACCOUNT_ID:role/service-role/CloudFormation
source_profile = default
mfa_serial = arn:aws:iam::IAM_ACCOUNT_ID:mfa/IAM_USERNAME
output = json
region = eu-west-1
```

Suggested profile names:

* cloudformation@backup
* cloudformation@husdyrfag-iam
* cloudformation@husdyrfag-sandbox
* cloudformation@husdyrfag-ops
* cloudformation@husdyrfag-dev
* cloudformation@husdyrfag-staging
* cloudformation@husdyrfag-prod
* cloudformation@openfarm-sandbox
* cloudformation@openfarm-dev
* cloudformation@openfarm-staging
* cloudformation@openfarm-prod
* cloudformation@master

<a id="cloudformation-user"></a>
## System users

Creates system users for use with CI/CD and other ops services:

```
hf-stack-deploy \
    -s \
    -p cloudformation@husdyrfag-staging \
    -f bootstrap/iam/users/config.json
```

Create access key for the `cloudformation` user:

```
./bootstrap/iam/users/create-access-key.sh \
    -f bootstrap/iam/users/access-key-config.json \
    -p cloudformation@husdyrfag-staging
```

<a id="iam"></a>
## More roles

Roles that developers can assume to peek around:

```sh
hf-stack-deploy \
    -s \
    -f bootstrap/iam/roles/developers.json \
    -p cloudformation@husdyrfag-staging
```

<a id="domains"></a>
## Route53 Domains

To work with Route53 you need to set the region flag to `us-east-1`.

### Check for domain availability

```sh
aws route53domains check-domain-availability \
    --domain-name husdyrfag.io \
    --region us-east-1 \
    --profile OrganizationAccountAccessRole@hfstaging
```

### Register domain

```
./registerDomain.sh -p <adminprofile>
```

You will be prompted for accountid, accountname and domainname.

After running this, check the status with
```
aws route53domains get-operation-detail --operation-id <id> --region us-east-1 --profile OrganizationAccountAccessRole@<AccountName>  (e.g. HusdyrfagSandbox)
```

### Remember to lock the domain

```sh
aws route53domains enable-domain-transfer-lock \
    --domain-name husdyrfag.io \
    --region us-east-1 \
    --profile OrganizationAccountAccessRole@hfstaging
```

### Set it to renew

```sh
aws route53domains enable-domain-auto-renew \
    --domain-name husdyrfag.io \
    --region us-east-1 \
    --profile OrganizationAccountAccessRole@hfstaging
```

<a id="hosted-zone"></a>
## Hosted Zone and workmail

When you register a domain with Route53 a hosted zone will be created for you.
In order to be able to refer to the hosted zone ID (for Cloudfront, Api Gateway
domain name mappings, etc) across Cloudformation, we'd like to create the hosted
zone ourselves through Cloudformation.

Amazon WorkMail, which is used primarily to receive domain-level emails for
`webmaster@account-domain` requires a few DNS records as well, so we will find
their value before spinning up the hosted zone.

Go to [Workmail](https://eu-west-1.console.aws.amazon.com/workmail/). Click
"Domains". Select the domain. On this page you will find all the values needed
to configure your domain:

```json
{
  "stackName": "HostedZones",
  "tags": {
    "CostCenter": "Husdyrfag",
    "SystemContext": "Platform"
  },
  "template": "hosted-zone.yml",
  "parameters": {
    "HostName": "husdyrfag-staging.io",
    "Environment": "husdyrfag-staging",
    "SESVerificationValue": "kSejS5BzljjMUA8oYEo2D9Zjez7upAiGTTXqpxhHlLU=",
    "MX": "10 inbound-smtp.eu-west-1.amazonaws.com.",
    "AutoDiscover": "autodiscover.mail.eu-west-1.awsapps.com.",
    "DkimVerification1": "ibopjdpbd3odytfalullupfdvon6ymb2",
    "DkimVerification2": "yan5ckpbgm6pupr3qlljwqm4onyr4dji",
    "DkimVerification3": "wvkoznexwd6cjsjbewujmdqjq23dr37v"
  }
}
```

When your configuration is complete, delete the automatically created hosted
zone:

```sh
aws route53 delete-hosted-zone \
    --profile cloudformation@husdyrfag-staging \
    --id ZWCJV0X732F14
```

The hosted zone ID can be found in the URL when looking at the hosted zone from
Route53.

Now create the Cloudformation stack:

```sh
hf-stack-deploy \
    -s \
    -p cloudformation@husdyrfag-staging \
    -f bootstrap/route53/hosted-zone-husdyrfag-staging.json
```

When the stack is created successfully, you need to update the domain to use the
nameservers that were assigned to your hosted zone. Look at the hosted zone in
Route53, copy the nameservers, and issue a command similar to the following
(replacing the nameservers, profile, and domain name):

```sh
aws route53domains update-domain-nameservers \
    --domain-name husdyrfag-staging.io \
    --nameservers Name=ns-1289.awsdns-33.org. Name=ns-592.awsdns-10.net. Name=ns-130.awsdns-16.com. Name=ns-1934.awsdns-49.co.uk. \
    --profile cloudformation@husdyrfag-staging \
    --region us-east-1
```

When the domain is verified in Workmail, you can proceed to create the
`webmaster` user.

<a id="infrastructure-bucket"></a>
## S3 Bucket

Creates an S3 bucket to use for infrastructure provisioning artifacts (such as
scripts to pre-install in EC2 instances, lambda sources, nested CloudFormation
stacks etc).

Configuration is provided for two buckets per account. There's one in
`eu-west-1`, where most of the resources should be created. Some services
require that certain resources (Cloudfront distributions, SSL certificates) are
created in the `us-east-1` region, so there is one bucket in that region for
each account as well.

```sh
hf-stack-deploy -s -p cloudformation@backup -f bootstrap/s3/backup.json
hf-stack-deploy -s -p cloudformation@husdyrfag-ops -f bootstrap/s3/husdyrfag-ops.json
hf-stack-deploy -s -p cloudformation@husdyrfag-ops -f bootstrap/s3/husdyrfag-ops-us-east.json
hf-stack-deploy -s -p cloudformation@husdyrfag-dev -f bootstrap/s3/husdyrfag-dev.json
hf-stack-deploy -s -p cloudformation@husdyrfag-dev -f bootstrap/s3/husdyrfag-dev-us-east.json
hf-stack-deploy -s -p cloudformation@husdyrfag-staging -f bootstrap/s3/husdyrfag-staging.json
hf-stack-deploy -s -p cloudformation@husdyrfag-staging -f bootstrap/s3/husdyrfag-staging-us-east.json
hf-stack-deploy -s -p cloudformation@husdyrfag-prod -f bootstrap/s3/husdyrfag-prod.json
hf-stack-deploy -s -p cloudformation@husdyrfag-prod -f bootstrap/s3/husdyrfag-prod-us-east.json

hf-stack-deploy -s -p cloudformation@openfarm-dev -f bootstrap/s3/openfarm-dev.json
hf-stack-deploy -s -p cloudformation@openfarm-dev -f bootstrap/s3/openfarm-dev-us-east.json
hf-stack-deploy -s -p cloudformation@openfarm-staging -f bootstrap/s3/openfarm-staging.json
hf-stack-deploy -s -p cloudformation@openfarm-staging -f bootstrap/s3/openfarm-staging-us-east.json
hf-stack-deploy -s -p cloudformation@openfarm-prod -f bootstrap/s3/openfarm-prod.json
hf-stack-deploy -s -p cloudformation@openfarm-prod -f bootstrap/s3/openfarm-prod-us-east.json
```

<a id="vpc"></a>
## VPC

The VPC template configures a VPC with one private and one public subnet in each
availability zone. The network houses the following subnets:

* Private subnet `10.0.0.0/20` (AZ A)
* Private subnet `10.0.64.0/20` (AZ B)
* Private subnet `10.0.128.0/20` (AZ C)
* Public subnet `10.0.63.0/24` (AZ A)
* Public subnet `10.0.127.0/24` (AZ B)
* Public subnet `10.0.191.0/24` (AZ C)

To install or update the network:

```sh
hf-stack-deploy -s -p cloudformation@husdyrfag-staging -f bootstrap/vpc/husdyrfag.json
```

<a id="ssl"></a>
## SSL Certificate

In some cases, SSL certificates needs to live with basic infrastructure. For
example, in order to terminate SSL on the ECS internet-facing load balancer, the
load balancer needs a reference to the SSL certificates for all domains it is
going to handle. This has the potential of creating an iffy list of sites running
in the load balancer, in addition to the rules that individual apps set up to
register themselves with the load balancer.

To avoid any specifics seeping into the infrastructure repository, this setup
provisions only one SSL certificate - a wildcard certificate for subdomains on
the main account domain.

Because some services require that certificates exist in the `us-east-1` region
(Cloudfront), and others require that certificates exist in the same region as
the resource it is used with (load balancers), we provision each certificate
twice, once for `eu-west-1` and once for `us-east-1`.

NB! Provisioning a certificate generates an email to webmaster@husdyrfag.io,
which needs to be reacted to manually. The password can be found
[on Confluence](https://confluence.tine.no/display/TDOC/AWS+Mail+accounts).
Email login is at e.g.
[https://husdyrfag-staging.awsapps.com/mail](https://husdyrfag-staging.awsapps.com/mail).

```sh
hf-stack-deploy -p cloudformation@husdyrfag-staging -f bootstrap/ssl/husdyrfag-staging.json -r us-east-1
hf-stack-deploy -p cloudformation@husdyrfag-staging -f bootstrap/ssl/husdyrfag-staging.json
```

<a id="domain-transfer"></a>
## Domain transfer

The husdyrfag.io domain was transferred from the old master (032335054161) to
the new husdyrfag account. (576279076904) When transferring, no configuration
was transferred with it, so we have to reconfigure the hosted zone.

The following commands have been run (note the `us-east-1` region):

```sh
aws route53domains enable-domain-transfer-lock --domain-name husdyrfag.io \
                                               --profile cloudformation@husdyrfag \
                                               --region us-east-1
aws route53domains update-domain-nameservers \
    --domain-name husdyrfag.io \
    --nameservers Name=ns-1289.awsdns-33.org. Name=ns-592.awsdns-10.net. Name=ns-130.awsdns-16.com. Name=ns-1934.awsdns-49.co.uk. \
    --profile cloudformation@husdyrfag \
    --region us-east-1
```

To change TTL for NS records, run

```sh
aws route53 change-resource-record-sets \
    --hosted-zone-id Z58RR2DZCLLEA \
    --change-batch file://bootstrap/route53/change-ttl-for-NS-skeleton.json \
    --profile cloudformation@husdyrfag \
    --region us-east-1

aws route53 get-change --id /change/C2GBNBV51GTNXG --profile cloudformation@husdyrfag --region us-east-1
```
