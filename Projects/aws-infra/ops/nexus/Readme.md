# Nexus

The Nexus stack requires working [container infrastructure](../../containers/Readme.md).

```sh
hf-stack-deploy -p cloudformation@husdyrfag-ops -f ops/nexus/config.json
```

## Create SES SMTP Credentials

SES SMTP credentials must be manually created in the console as `root` as there
is no CLI or CloudFormation options to do it. To verify the email address to use
SES, the following was run:

```sh
aws ses verify-email-identity --email-address nexus@husdyrfag-ops.io --profile cloudformation@husdyrfag-ops
```

This will generate an email. Log into the workmail account, and find it there.
