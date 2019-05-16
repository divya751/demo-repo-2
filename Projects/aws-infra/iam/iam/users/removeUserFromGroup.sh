#!/bin/bash

eval $(hf-getopt "$@")

read -p "Please enter the username: " username
read -p "Group you want to remove $username from: " group


hf-remove-user-from-group $group $username "$aws_args"
