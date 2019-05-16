#!/bin/bash

eval $(hf-getopt "$@")
aws organizations create-organization $aws_args --cli-input-json "file://$config_file"
