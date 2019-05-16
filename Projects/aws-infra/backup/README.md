# Backup account

This account is setup as the BACKUP account for Husdyrfag. There are no links
between the Husdyrfag account and this account, other than backing up resources
to S3 buckets.

To access this account you will have to have a user account *local to this AWS
account*.

See [bootstrap README](../bootstrap/README.md) for instructions on setting up an
account.

After these manual steps the following commands have been created and run in
scripts.

## Admin group

```sh
hf-stack-deploy -p cloudformation@backup -f backup/groups/config.json
```
