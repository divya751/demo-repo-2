#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Create user $username, do you wish to proceed? [y|n] " yn

case $yn in
  [Yy]* )
    echo "Creating.."
    aws iam create-user $aws_args --user-name $username
    aws iam create-login-profile $aws_args --user-name $username --password "!ChangeThis123" --password-reset-required
    aws iam attach-user-policy --policy-arn arn:aws:iam::751750612325:policy/iammpChangePassword --user-name $username $aws_args
    #aws iam create-access-key $aws_args --user-name $username

    read -p "Do you want to add $username to the developer group [y|n] " yn

    case $yn in
      [Yy]* )
        hf-add-user-to-group Developers $username $profile
        ;;
      [Nn]* ) echo "Skipping developer group" ;;
      * ) exit ;;
    esac

    # read -p "Do you want to add $1 to the BILLING group [y|n] " yn

    # case $yn in
    #   [Yy]* )
    #     hs-add-user-to-group Billing $username $profile
    #     ;;
    #   [Nn]* ) echo "Skipping billing group" ;;
    #   * ) exit ;;
    # esac

    # read -p "Do you want to add $1 to the ADMIN group [y|n] " yn

    # case $yn in
    #   [Yy]* )
    #     hf-add-user-to-group Admin $username $profile
    #     ;;
    #   [Nn]* ) echo "Skipping admin group" ;;
    #   * ) exit ;;
    # esac


    ;;
  [Nn]* ) exit ;;
  * ) exit ;;
esac

