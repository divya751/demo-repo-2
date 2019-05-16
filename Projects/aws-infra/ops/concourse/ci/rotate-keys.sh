#!/bin/bash

set -e

function rotate-key() {
  team="$1"
  environment="$2"

  echo "Rotating $team $environment"

  key_id=$(credhub get -j --name /concourse/${team}/${environment}_key_id | jq -cr '.value')
  echo "  Replacing key $key_id"
  key_secret=$(credhub get -j --name /concourse/${team}/${environment}_key_secret | jq -cr '.value')
  access_key=$(env AWS_ACCESS_KEY_ID="$key_id" AWS_SECRET_ACCESS_KEY="$key_secret" \
                   aws iam create-access-key --user-name ConcourseWorker)

  if [ $? -eq 0 ]; then
    new_key_id=$(echo "$access_key"  | jq -cr '.AccessKey.AccessKeyId')
    new_key_secret=$(echo "$access_key"  | jq -cr '.AccessKey.SecretAccessKey')
    echo "  Created new key $new_key_id"

    credhub set --type password --name /concourse/${team}/${environment}_key_id --password "$new_key_id"
    credhub set --type password --name /concourse/${team}/${environment}_key_secret --password "$new_key_secret" | sed s#${new_key_secret}#\*\*\*#g

    env AWS_ACCESS_KEY_ID="$key_id" AWS_SECRET_ACCESS_KEY="$key_secret" \
        aws iam delete-access-key --access-key-id "$key_id" --user-name ConcourseWorker
  else
    echo "  Failed to create new AWS key"
  fi
}

if [ ! -z "$credhub_password" ]; then
    credhub login \
            --client-name=credhub_cli \
            --client-secret="$credhub_password" \
            --server="$credhub_server" \
            --ca-cert "$credhub_certificate"

    if [ $? -ne 0 ]; then
        echo "Failed to login to credhub, aborting"
        exit 1
    fi
fi

rotate-key husdyrfag dev
rotate-key husdyrfag staging
rotate-key husdyrfag prod

rotate-key openfarm dev
rotate-key openfarm staging
rotate-key openfarm prod

# ECR/OPS keys, must propagate to both teams
rotate-key husdyrfag ecr

key_id=$(credhub get -j --name /concourse/husdyrfag/ecr_key_id | jq -cr '.value')
key_secret=$(credhub get -j --name /concourse/husdyrfag/ecr_key_secret | jq -cr '.value')

credhub set --type password --name /concourse/openfarm/ecr_key_id --password "$key_id"
credhub set --type password --name /concourse/openfarm/ecr_key_secret --password "$key_secret" | sed s#${key_secret}#\*\*\*#g
