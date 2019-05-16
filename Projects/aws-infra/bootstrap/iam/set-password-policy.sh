#!/bin/bash

eval $(hf-getopt "$@")
aws iam update-account-password-policy --cli-input-json "file://$config_file" $aws_args
