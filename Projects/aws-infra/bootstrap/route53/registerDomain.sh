#!/bin/bash

eval $(hf-getopt "$@")

read -p "Account id: " accountId
read -p "Account name: " accountName
read -p "Please enter the domainname: " domainname
read -p "Registering $domainname, do you wish to proceed? [y|n] " yn

aws sts assume-role --role-arn arn:aws:iam::$accountId:role/OrganizationAccountAccessRole --role-session-name orgAdminAt$accountName $aws_args > output
assumeInfo=$(<output)

accessKeyId=($(echo "$assumeInfo" | jq -r .Credentials.AccessKeyId))
secretAccessKey=($(echo "$assumeInfo" | jq -r .Credentials.SecretAccessKey))
sessionToken=($(echo "$assumeInfo" | jq -r .Credentials.SessionToken))

cat << EOF

Copy the following to your .aws/config file

[profile OrganizationAccountAccessRole@$accountName]
output = json
region = eu-west-1

And the following to your .aws/credentials file

[OrganizationAccountAccessRole@$accountName]
aws_access_key_id = $accessKeyId
aws_secret_access_key = $secretAccessKey
aws_session_token = $sessionToken


EOF

read -p "Press enter when ready: " foo


case $yn in
  [Yy]* )
    aws route53domains register-domain --region us-east-1 --domain-name $domainname --cli-input-json "file://registerDomain.json" --profile OrganizationAccountAccessRole@$accountName
    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac

rm output


#aws route53domains get-operation-detail --operation-id a4747d6b-ef32-4979-9c56-09e8ab13e011 --region us-east-1 --profile OrganizationAccountAccessRole@$accountName
