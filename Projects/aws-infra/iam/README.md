# IAM account

This account is used for IAM only!

**The IAM account hosts all IAM users.** Users can assume roles
(typically `ReadOnly`) to access the Husdyrfag account.

See [bootstrap README](../bootstrap/README.md) for instructions on setting up an
account.

After these manual steps the following commands have been created and run in
scripts.

## Manual steps in the IAM account

| Action     | Comment     |
| :------------- | :------------- |
| After groups have been created, initial user belonging to iamgHfIAMAdmin was created in the GUI | To enable creating other users |

## CLI commands

### createUser.sh (iam/users/createUser.sh)

Scripts to create users in the Iam account. The script will prompt you for
username and groups the user should be added to.

NB!: The Group template must be applied first.

## CloudFormation templates for IAM

### IAM::Group

IAM configuration for the iam account includes the `Developers` group.
This group has a managed policy that allows its users to access any service
except for billing so long as the user is authenticated with an MFA device. Most
of IAM is locked down as well, except for basic introspection and managing the
user's own resources (SSH keys, password, etc).

The group config also creates the Admin and Billing groups.

To install group:

```sh
hf-stack-deploy -s -p cloudformation@husdyrfag-iam -f iam/iam/groups/config.json
```
