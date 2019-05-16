#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Group you want to add $username to: " group


hf-add-user-to-group $group $username "$aws_args"
