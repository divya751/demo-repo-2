#!/bin/bash

eval $(hf-getopt "$@")
aws iam create-access-key --cli-input-json "file://$config_file" $aws_args
