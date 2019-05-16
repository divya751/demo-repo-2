#!/bin/bash

eval $(hf-getopt "$@")

read -p "Account id: " id

read -p "Source parent id (enter for default): " sourceid
sourceid=${sourceid:-r-7mmv}

read -p "Destination parent id (enter for default): " destid
destid=${destid:-ou-7mmv-qme3q3rg}

echo "Moving account $id from $sourceid to $destid"

# aws organizations list-organizational-units-for-parent --parent-id ou-7mmv-mgpekjv0 $aws_args --query 'OrganizationalUnits[*].[Id, Name]' --output text
aws organizations move-account --account-id $id --source-parent-id $sourceid --destination-parent-id $destid $aws_args
