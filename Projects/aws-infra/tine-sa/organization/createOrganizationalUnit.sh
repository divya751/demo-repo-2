#!/bin/bash

eval $(hf-getopt "$@")
aws organizations create-organizational-unit $aws_args --cli-input-json "file://$config_file"
