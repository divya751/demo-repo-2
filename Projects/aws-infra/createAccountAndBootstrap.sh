#!/bin/bash

eval $(hf-getopt "$@")
./tine-sa/organization/createAccount.sh "$@" > output

createinfo=$(<output)
createId=($(echo "$createinfo" | jq -r .CreateAccountStatus.Id))
accountName=($(echo "$createinfo" | jq -r .CreateAccountStatus.AccountName))
# echo $createId
createStatus=""
accountId=""

while [[ $createStatus != "SUCCEEDED" ]]; do
  aws organizations describe-create-account-status --create-account-request-id $createId $aws_args > output
  createStatusInfo=$(<output)
  createStatus=($(echo "$createStatusInfo" | jq -r .CreateAccountStatus.State))
  accountId=($(echo "$createStatusInfo" | jq -r .CreateAccountStatus.AccountId))
  echo $createStatus
done

echo "Account created with id $accountId"

./tine-sa/organization/moveAccount.sh "$@"

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

read -p "Account alias: " alias

aws iam create-account-alias --account-alias $alias --profile OrganizationAccountAccessRole@$accountName

./bootstrap/iam/set-password-policy.sh -f bootstrap/iam/password-policy-config.json -p OrganizationAccountAccessRole@$accountName

hf-stack-deploy -s -f bootstrap/iam/roles/cloudformation.json -p OrganizationAccountAccessRole@$accountName

read -p "Enter domainname, we will check for availability: " domainname
aws route53domains check-domain-availability --domain-name $domainname --region us-east-1 --profile OrganizationAccountAccessRole@$accountName

read -p "Do you want to register the domain [y|n] " yn

case $yn in
  [Yy]* )
    pushd bootstrap/route53/
    ./registerDomain.sh "$@"
    popd
    ;;
  [Nn]* ) echo "Skipping domain registration" ;;
  * ) exit ;;
esac


cat << EOF
Complete the setup by performing the following steps

* If not already done, register a domain using the script bootstrap/route53/registerDomain.sh
* Access the AWS console login screen, and request a password change  (https://console.aws.amazon.com/console/home)
* Log in as root
* Setup Workmail for the domain
* Register "webmaster" as a Workmail user
* Update documentation in Confluence!
  - https://confluence.tine.no/display/TDOC/AWS+Accounts
  - https://confluence.tine.no/display/TDOC/AWS+Groups+-+Roles+-+Policies
  - https://confluence.tine.no/pages/viewpage.action?pageId=79892719
  - https://confluence.tine.no/display/TDOC/AWS+Mail+accounts
  - https://confluence.tine.no/display/TDOC/Root+Account+info

EOF

echo "done"

rm output
