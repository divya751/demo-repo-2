#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Create user $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )
    echo "Creating.."
    aws iam create-user $aws_args --user-name $username --path /service/
    aws iam create-access-key $aws_args --user-name $username
    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac
