#!/usr/bin/env bash

eval $(hf-getopt "$@")

organizationAlias="${@: -1}"

if [ -z "${aws_args}" ] || [ $# -lt 3 ]; then
  echo "  Usage:"
  echo "    $0 -p cloudformation@<environment> <organizationAlias>"
  exit 1
fi

organizationId=$(aws workmail list-organizations ${aws_args} | \
  jq -r ".OrganizationSummaries[] | select(.Alias==\"${organizationAlias}\") | .OrganizationId ")

if [ -z $organizationId ]; then
  "Error: No organization with the alias ${organizationAlias} was found"
  exit 1
fi

displayName=$(echo ${organizationAlias} | sed -r 's/(^|-)(\w)/\U\2/g')

echo "Create webmaster user for ${organizationAlias}"
echo -n "Set email: "
read email
echo -n "Set password: "
read -s password
echo

userId=$(aws workmail create-user \
            --organization-id ${organizationId} \
            --name webmaster \
            --display-name "Webmaster ${displayName}" \
            --password ${password} \
            ${aws_args} | \
            jq -r .UserId)

aws workmail register-to-work-mail \
  --organization-id ${organizationId} \
  --entity-id ${userId} \
  --email ${email} \
  ${aws_args}
