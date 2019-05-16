#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Create user $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )
    echo "Creating.."

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


    aws iam create-user $aws_args --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam create-login-profile $aws_args --user-name $username --password "!ChangeThis123" --password-reset-required --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam attach-user-policy --policy-arn arn:aws:iam::669632543524:policy/iammpChangePassword --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    aws iam add-user-to-group --group-name iamgAdmin --user-name $username --profile OrganizationAccountAccessRole@orgAdminAtHusdyrfagBackup
    #aws iam create-access-key $aws_args --user-name $username

    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac

