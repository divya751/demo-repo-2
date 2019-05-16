#!/bin/bash

# hf-stack-delete -y -p cf@hf-ops -f concourse.json

# output=''

# while [[ $output != *"Stack with id ConcourseDNS does not exist"* ]]; do
#   hf-stack-describe -p cf@hf-ops -f concourse.json &> outputfile
#   output=$(<outputfile)
#   echo "Deleting stack"
#   sleep 5
# done

# echo "Stack is deleted"

# hostedZone=$(aws route53 list-hosted-zones --profile cf@hf-ops | jq -r '.HostedZones[] | select(.Name == "husdyrfag-ops.io.").Id')
# #echo $hostedZone
# ip=$(aws route53 list-resource-record-sets --hosted-zone-id $hostedZone --profile cf@hf-ops | jq -r '.ResourceRecordSets[] | select(.Name == "ci.husdyrfag-ops.io.").ResourceRecords[].Value')

ip=10.0.1.1
if [[ ! -z $ip ]];
then
  echo "Updating delete-concourse-A-record.json with $ip"

  jqresult="$(cat delete-concourse-A-record.json |jq ".Changes[].ResourceRecordSet.ResourceRecords[].Value |= \"$ip\"")"
  echo $jqresult
  cat <<< "$jqresult" > delete-concourse-A-record.json
fi;

# echo "Deleting record set"
# changeid=$(aws route53 change-resource-record-sets --hosted-zone-id $hostedZone --change-batch file://delete-concourse-A-record.json --profile cf@hf-ops | jq -r '.ChangeInfo.Id')
# echo "Change id is $changeid"

# changestatus=""
# while [[ $changestatus != "INSYNC"  && ! -z $changeid ]]; do
#   changestatus=$(aws route53 get-change --id $changeid --profile cf@hf-ops  | jq -r '.ChangeInfo.Status')
#   echo "Status is $changestatus"
#   sleep 5
# done

# echo "Status is $changestatus"

# instanceid=$(aws ec2 describe-instances --filters Name=instance-state-code,Values=16 --profile cf@hf-ops | jq -r '.Reservations[].Instances[] | select(.Tags[].Key=="job") | select(.Tags[].Value == "web").InstanceId')

instanceid=foobar
echo "Updating concourse.json with correct $instanceid"


jqresult="$(cat concourse.json |jq ".parameters.InstanceId |= \"$instanceid\"")"
echo $jqresult
cat <<< "$jqresult" > concourse.json


# hf-stack-deploy -y -p cf@hf-ops -f concourse.json

# stackstatus=''
# while [[ $stackstatus != "CREATE_COMPLETE" ]]; do
#   stackstatus=$(hf-stack-describe -p cf@hf-ops -f concourse.json | jq -r '.Stacks[].StackStatus')
#   echo "Status is $stackstatus"
#   sleep 5
# done

# echo "Stack is created"


# rm outputfile
