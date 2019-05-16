# Bastion server

The bastion server allows SSH access to EC2 instances. The default security
groups restrict network traffic to the bare minimum, which means that there is
no way to enter an EC2 instance from outside of the VPC in which it runs.

The bastion server has a security group that allows inbound SSH from Tine's IP
address. By temporarily placing it in a VPC, you can enter EC2 instances by
connecting to the bastion server over SSH, and then reach the EC2 instance in
question.

The bastion requires a few files in the S3 infrastructure bucket, start by
making sure they're present and up to date:

```sh
hf-upload-artifacts -p cloudformation@husdyrfag-staging -f bastion/config.json
```

The bastion needs a keypair in order for anyone to be able to access it
(password logins are disabled for security). The bastion server is set up to use
the `bastion` keypair. The private key can be found in
[https://github.com/TINE-SA/tine-cloud-pipelines#credhub](credhub):

```sh
credhub get --name /aws/keys/openfarm_staging_bastion_key -j | jq -cr '.value.private_key' > /tmp/bastion_key
```

The following keys are available:

- `/aws/keys/openfarm_dev_bastion_key`
- `/aws/keys/openfarm_staging_bastion_key`
- `/aws/keys/openfarm_prod_bastion_key`
- `/aws/keys/husdyrfag_dev_bastion_key`
- `/aws/keys/husdyrfag_staging_bastion_key`
- `/aws/keys/husdyrfag_prod_bastion_key`
- `/aws/keys/husdyrfag_sandbox_bastion_key`

Keys can be created locally and imported into AWS thusly:

```sh
ssh-keygen -t rsa -b 4096 -C "AWS Bastion"

aws ec2 import-key-pair --profile cloudformation@husdyrfag-staging \
                        --key-name bastion \
                        --public-key-material file://bastion-key.pub

credhub set \
    --name /aws/keys/husdyrfag_staging_bastion_key \
    --private bastion \
    --public bastion.pub
```

With the key in place, deploy the stack:

```sh
hf-stack-deploy -p cloudformation@husdyrfag-staging -f bastion/config.json
```

The entire Bastion stack will be scheduled for termination after three hours.
If you are done with it before then, feel free to terminate it earlier.

## Remote CIDR address

By default the bastion will only accept connections from Tine's on-premise
public IP. If you for some reason are unable to access via this, and you really
(I mean, _really_) need to access an EC2 instance, you can override the
`RemoteAccessCIDR` in the appropriate configuration file to match your current
IP.
