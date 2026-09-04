#!/usr/bin/env bash
set -euo pipefail

: "${EC2_INSTANCE_ID:?Set EC2_INSTANCE_ID to the instance to terminate}"
: "${AWS_REGION:=eu-west-1}"
aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids "$EC2_INSTANCE_ID"
echo "Termination requested for $EC2_INSTANCE_ID in $AWS_REGION."
