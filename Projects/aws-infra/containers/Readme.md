# Container infrastructure

The container infrastructure consists of an auto-scalable cluster with an
internet-facing load balancer accepting HTTP/HTTPS traffic on port 80/443 as
well as an internal load balancer with private DNS resolution for service
discovery.

<a id="keypairs"></a>
## Keypairs

Cluster instances need a keypair in order for anyone to be able to access them
(in the hopefully rare cases that is needed). Cluster instances are set up to
use the `ecs-ec2-instances` keypair. The private key can be found in
[https://github.com/TINE-SA/tine-cloud-pipelines#credhub](credhub):

```sh
credhub get --name /aws/keys/openfarm_staging_ec2_key -j | jq -cr '.value.private_key' > /tmp/ec2_key
```

The following keys are available:

- `/aws/keys/openfarm_dev_ec2_key`
- `/aws/keys/openfarm_staging_ec2_key`
- `/aws/keys/openfarm_prod_ec2_key`
- `/aws/keys/husdyrfag_dev_ec2_key`
- `/aws/keys/husdyrfag_staging_ec2_key`
- `/aws/keys/husdyrfag_prod_ec2_key`
- `/aws/keys/husdyrfag_sandbox_ec2_key`

Keys can be created locally and imported into AWS thusly:

```sh
ssh-keygen -t rsa -b 4096 -C "AWS ECS EC2 Instance"

aws ec2 import-key-pair --profile cloudformation@husdyrfag-staging \
                        --key-name ec2-ec2-instances \
                        --public-key-material file://ec2-key.pub

credhub set \
    --name /aws/keys/husdyrfag_staging_ec2_key \
    --private ec2-key \
    --public ec2-key.pub
```

<a id="iam"></a>
## IAM Roles and policies

The IAM resources makes sure the cluster is granted permissions required to
manage its EC2 instances (take EC2 instances in/out of the cluster, etc).

Install the IAM roles and policies once per account:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-dev -f containers/iam/husdyrfag-dev.json
hf-stack-deploy -p cloudformation@husdyrfag-staging -f containers/iam/husdyrfag-staging.json
hf-stack-deploy -p cloudformation@husdyrfag-prod -f containers/iam/husdyrfag-prod.json

hf-stack-deploy -p cloudformation@openfarm-dev -f containers/iam/openfarm-dev.json
hf-stack-deploy -p cloudformation@openfarm-staging -f containers/iam/openfarm-staging.json
hf-stack-deploy -p cloudformation@openfarm-prod -f containers/iam/openfarm-prod.json
```

To obtain KmsDefaultKeyId run:
```sh
aws kms describe-key --profile cloudformation@husdyrfag-dev --key-id alias/aws/ssm
```

<a id="filesystem"></a>
## EFS Filesystem

The cluster mounts an EFS filesystem in order to offer containers an option for
persistent disk storage. This is not an ideal way to store data, and should
probably be avoided if at all possible. Still, sometimes (e.g., when using
externally developed software, like Nexus) there's no way around some persistent
disk, and that's what the EFS share is for.

The EFS filesystem is set up along with the rest of the nested stack, as it
references the ECS EC2 instance security group.

<a id="setup"></a>
## Configuration files

The EC2 requires a configuration file from S3 infrastructure bucket, start by 
making sure they're present and up to date:

```sh
hf-upload-artifacts -p cloudformation@husdyrfag-dev -f containers/husdyrfag-dev.json
hf-upload-artifacts -p cloudformation@husdyrfag-staging -f containers/husdyrfag-staging.json
hf-upload-artifacts -p cloudformation@husdyrfag-prod -f containers/husdyrfag-prod.json

hf-upload-artifacts -p cloudformation@openfarm-dev -f containers/openfarm-dev.json
hf-upload-artifacts -p cloudformation@openfarm-staging -f containers/openfarm-staging.json
hf-upload-artifacts -p cloudformation@openfarm-prod -f containers/openfarm-prod.json
```

## Set up cluster and load balancers

The cluster and load balancers reside in separate templates, but can be set up
in one go with the nested stack:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-dev -f containers/husdyrfag-dev.json
hf-stack-deploy -p cloudformation@husdyrfag-staging -f containers/husdyrfag-staging.json
# NB! Separate config for production (longer connection draining timeout)
hf-stack-deploy -p cloudformation@husdyrfag-prod -f containers/husdyrfag-prod.json
# NB! Bigger instances
hf-stack-deploy -p cloudformation@husdyrfag-ops -f containers/husdyrfag-ops.json

hf-stack-deploy -p cloudformation@openfarm-dev -f containers/openfarm-dev.json
hf-stack-deploy -p cloudformation@openfarm-staging -f containers/openfarm-staging.json
# NB! Separate config for production (longer connection draining timeout)
hf-stack-deploy -p cloudformation@openfarm-prod -f containers/openfarm-prod.json
```

<a id="load-balancers"></a>
## Load balancers

The cluster stack brings up two load balancers: an internet-facing one for
services that should be available directly for the public, and an internal one
for services that should only be available internally. For public-facing
services, you need to provide a .husdyrfag.io subdomain. For internal services,
use a ".service" subdomain, like myapp.service. These DNS names are only
resolvable within the VPC, and myapp.service within the development VPC will
resolve to the development version of "myapp", while the same DNS name will
route to the staging version in the staging VPC.

<a id="capacity-scaling"></a>
## Cluster capacity and scaling

The current configuration creates a cluster of minimum 2 machines with 2GB RAM
and 1 CPU. The cluster will auto-scale when either 75% of the available memory
or 75% of the CPU is reserved for tasks running on the cluster. Scaling alarms
only trigger on metrics collected from running tasks. Specifically, attempting
to launch a task that requests more than the available resources will **not**
trigger scaling - instead, the service will just fail to start.

In other words, the current setup is only guaranteed to accept new services that
require up to 25% of the current CPU and memory capacity of the cluster. When
the cluster is at its minimum size, this means up to 512 CPU units and up to
1024MB of RAM. The cluster will be able to run services that require up to 1024
CPU units and 2048MB of RAM, but you might have to manually scale up the cluster
to be able to deploy them. If you require more resources for a single service,
bigger instances must be added to the cluster.

These settings are guaranteed to change as we collect experience and run more
apps on the cluster. Limits are set conservatively at this point to reduce cost
before anything is live.

<a id="metrics-logging"></a>
## Metrics and logging

The main AWS integration with Datadog platform can be found in metrics-logs/datadog
and has to be activated to obtain metrics from AWS account.

### Datadog agent

To enable detailed metrics for ECS the Datadog agent has to load one
container on each EC2 instance running in the cluster. The cluster stack creates 
agent ECS Task and includes the extra configuration in startup script for 
EC2(UserData). Refer to https://docs.datadoghq.com/integrations/amazon_ecs/#installation
for more detailed documentation.
