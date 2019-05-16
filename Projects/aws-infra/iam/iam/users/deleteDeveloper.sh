#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Deleting developer $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )
    echo "Deleting.."
    aws iam remove-user-from-group --group-name Developers --user-name $username $aws_args
    aws iam detach-user-policy --user-name $username --policy-arn arn:aws:iam::751750612325:policy/iammpChangePassword $aws_args
    # aws iam list-virtual-mfa-devices $aws_args
    aws iam deactivate-mfa-device --serial-number arn:aws:iam::751750612325:mfa/$username  --user-name $username
    aws iam delete-virtual-mfa-device --serial-number arn:aws:iam::751750612325:mfa/$username
    aws iam delete-login-profile $aws_args --user-name $username
    aws iam delete-user $aws_args --user-name $username
    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac
