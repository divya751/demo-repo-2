#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Deleting developer $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )

    echo "Deleting.."

    # aws sts assume-role --role-arn arn:aws:iam::669632543524:role/OrganizationAccountAccessRole --role-session-name orgAdminAtHusdyrfagBackup $aws_args > output

    assumeInfo=$(<output)

    accessKeyId=($(echo "$assumeInfo" | jq -r .Credentials.AccessKeyId))
    secretAccessKey=($(echo "$assumeInfo" | jq -r .Credentials.SecretAccessKey))
    sessionToken=($(echo "$assumeInfo" | jq -r .Credentials.SessionToken))

cat << EOF

Copy the following to your .aws/config file

[profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup]
output = json
region = eu-west-1

And the following to your .aws/credentials file

[OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup]
aws_access_key_id = $accessKeyId
aws_secret_access_key = $secretAccessKey
aws_session_token = $sessionToken
EOF

    read -p "Press enter when ready: " foo



    echo "Deleting.."
    aws iam remove-user-from-group --group-name iamgAdmin --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam detach-user-policy --user-name $username --policy-arn arn:aws:iam::669632543524:policy/iammpChangePassword --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam delete-login-profile --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam delete-user --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac
