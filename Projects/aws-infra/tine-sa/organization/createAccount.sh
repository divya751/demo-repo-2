#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the accountname: " accountname
read -p "Please enter the root email address: " email

aws organizations create-account --email $email --account-name $accountname $aws_args
