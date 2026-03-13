#!/bin/bash
# 2.1_vpcs/discovery.sh
PROJECT_TAG="capstone"

echo "🔍 Step 2.1: Discovering VPCs for Project=$PROJECT_TAG..."

# 1. Find VPCs by tag
VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "Vpcs[*].VpcId" \
  --output text)

aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "Vpcs[*].{ID:VpcId, CIDR:CidrBlock, Name:Tags[?Key=='Name']|[0].Value}" \
  --output table

for VPC_ID in $VPC_IDS; do
    VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[0].Tags[?Key=='Name']|[0].Value" --output text)
    echo -e "\n--- Detailed Audit for VPC: $VPC_NAME ($VPC_ID) ---"
    
    # 2. Find Internet Gateway
    echo "IGW Discovery:"
    aws ec2 describe-internet-gateways \
      --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
      --query "InternetGateways[*].{IGW_ID:InternetGatewayId, State:Attachments[0].State}" \
      --output table

    # 3. List Route Tables and Associations
    echo "Route Table Discovery:"
    aws ec2 describe-route-tables \
      --filters "Name=vpc-id,Values=$VPC_ID" \
      --query "RouteTables[*].{RT_ID:RouteTableId, Name:Tags[?Key=='Name']|[0].Value, Associations:Associations[*].SubnetId, Routes:Routes[*].{Dest:DestinationCidrBlock, IGW:GatewayId, NAT:NatGatewayId}}" \
      --output json | jq .
done
