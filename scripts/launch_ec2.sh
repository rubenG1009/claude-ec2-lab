#!/usr/bin/env bash
set -euo pipefail

# Launch one small Amazon Linux 2023 instance in the default VPC.
: "${AWS_REGION:=eu-west-1}"
: "${EC2_INSTANCE_TYPE:=t3.micro}"
: "${EC2_KEY_NAME:?Set EC2_KEY_NAME to an existing EC2 key-pair name}"

command -v aws >/dev/null || { echo "aws CLI is required" >&2; exit 1; }
MY_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"
VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)"

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "No default VPC in $AWS_REGION. Create/select a VPC before continuing." >&2
  exit 1
fi

SG_NAME="claude-ec2-lab-$(date +%Y%m%d%H%M%S)"
SG_ID="$(aws ec2 create-security-group --region "$AWS_REGION" --group-name "$SG_NAME" --description "Claude EC2 lab" --vpc-id "$VPC_ID" --query GroupId --output text)"
aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP/32" >/dev/null
aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --protocol tcp --port 8000 --cidr "$MY_IP/32" >/dev/null

INSTANCE_ID="$(aws ec2 run-instances \
  --region "$AWS_REGION" \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type "$EC2_INSTANCE_TYPE" \
  --key-name "$EC2_KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --metadata-options HttpTokens=required,HttpEndpoint=enabled \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=claude-ec2-lab},{Key=Project,Value=claude-ec2-lab}]" \
  --query 'Instances[0].InstanceId' --output text)"

aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"
PUBLIC_IP="$(aws ec2 describe-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
printf 'INSTANCE_ID=%s\nPUBLIC_IP=%s\nSECURITY_GROUP_ID=%s\nAWS_REGION=%s\n' "$INSTANCE_ID" "$PUBLIC_IP" "$SG_ID" "$AWS_REGION"
