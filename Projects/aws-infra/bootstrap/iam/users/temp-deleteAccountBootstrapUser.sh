#!/bin/bash

eval $(hf-getopt "$@")

aws iam detach-user-policy $aws_args \
    --user-name accountbootstrap \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam delete-user --user-name accountbootstrap $aws_args
