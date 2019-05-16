#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username

aws iam list-access-keys --user-name $username $aws_args

read -p "Enter access key id: " accessKey

echo "Deleting.."
aws iam delete-access-key --user-name $username --access-key-id $accessKey $aws_args
