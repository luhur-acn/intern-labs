#!/bin/bash
# 2.5_gateways/discovery.sh
PROJECT_TAG="capstone"

echo "🔍 Step 2.5: Discovering Elastic IPs (EIP)..."
aws ec2 describe-addresses \
  --query "Addresses[*].{AllocationID:AllocationId, PublicIP:PublicIp, AssociationID:AssociationId, Instance:InstanceId, Interface:NetworkInterfaceId}" \
  --output table

echo -e "\n🔍 Step 2.5: Discovering NAT Gateways for Project=$PROJECT_TAG..."
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "NatGateways[*].{ID:NatGatewayId, State:State, SubnetID:SubnetId, EIP:NatGatewayAddresses[0].PublicIp, AllocationID:NatGatewayAddresses[0].AllocationId}" \
  --output table

echo -e "\n🎯 Validation Task:"
echo "Cross-reference NAT Gateway's SubnetID against §2.2."
echo "Confirm each NAT Gateway is located in a PUBLIC subnet."
