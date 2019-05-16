#!/bin/bash

eval $(hf-getopt "$@")
read -p "Please enter the username: " username
read -p "Create user $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )
    echo "Creating.."
    aws iam create-user $aws_args --user-name $username
    echo "Creating access key.."
    aws iam create-access-key $aws_args --user-name $username
    # aws iam create-virtual-mfa-device --virtual-mfa-device-name ${username} --outfile ./QRCode.png --bootstrap-method QRCodePNG
    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac

read -p "Do you want to add $username to the organization-admin group [y|n] " yn

case $yn in
  [Yy]* )
    hf-add-user-to-group iamgAWSOrganizationAdmin $username $profile
    ;;
  [Nn]* ) echo "Skipping organization-admin group" ;;
  * ) exit ;;
esac
