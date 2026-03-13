#!/bin/bash
# 2.2_subnets/discovery.sh
PROJECT_TAG="capstone"

echo "🔍 Step 2.2: Discovering All Subnets for Project=$PROJECT_TAG..."

aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "Subnets[*].{ID:SubnetId, VPC:VpcId, CIDR:CidrBlock, AZ:AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value, AutoPublicIP:MapPublicIpOnLaunch}" \
  --output table

echo -e "\n💡 Validation Hint:"
echo "Public subnets: AutoPublicIP should be True."
echo "Private subnets: AutoPublicIP should be False."
