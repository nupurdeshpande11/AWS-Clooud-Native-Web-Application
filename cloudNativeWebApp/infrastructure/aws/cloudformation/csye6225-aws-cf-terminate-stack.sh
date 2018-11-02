#!/bin/bash -e

if [ -z "$1" ]
then
	echo "No command line argument provided for stack STACK_NAME"
	exit 1
else
	echo "Started with deletion of resources using cloud formation"
fi

RC=$(aws cloudformation describe-stacks --stack-name $1-application --query Stacks[0].StackId --output text)

if [ $? -eq 0 ]
then
	continue
else
	echo "Stack $1 doesn't exist"
	exit 0
fi

EC2_ID=$(aws ec2 describe-instances --filter "Name=tag:aws:cloudformation:stack-name,Values=$1-application" "Name=instance-state-code,Values=16" --query 'Reservations[*].Instances[*].{id:InstanceId}' --output text)

# Command to disable Termination Protection, It will disable it on a specific Instance, hence the instance Id is required
aws ec2 modify-instance-attribute --instance-id $EC2_ID --no-disable-api-termination

# Domain name for ARN
echo "Fetching domain name from Route 53"
DOMAIN_NAME=$(aws route53 list-hosted-zones --query HostedZones[0].Name --output text)


echo "Deleting stack: $RC"

aws cloudformation delete-stack --stack-name $1-application

echo "Stack deletion in progress. Please wait"
RC=$(aws cloudformation wait stack-delete-complete --stack-name $1-application)

if [ $? -eq 0 ]
then
  echo "Application stack deletion complete"
else
 	echo "Failed Stack deletion"
 	exit 1
fi

echo "Deleting networking stack"

aws cloudformation delete-stack --stack-name $1-networking

echo "Stack deletion in progress. Please wait"
RC=$(aws cloudformation wait stack-delete-complete --stack-name $1-networking)

if [ $? -eq 0 ]
then
  echo "Networking stack deletion complete"
else
 	echo "Failed Stack deletion"
 	exit 1
fi
