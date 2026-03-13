#!/bin/bash
# 2.3_ec2_instances/discovery.sh
PROJECT_TAG="capstone"

echo "🔍 Step 2.3: Discovering EC2 Instances for Project=$PROJECT_TAG..."

# 1. Find instances by tag and retrieve network details
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].{ID:InstanceId, Name:Tags[?Key=='Name']|[0].Value, Type:InstanceType, PrivateIP:PrivateIpAddress, SubnetID:SubnetId, VPC:VpcId, SGs:SecurityGroups[*].GroupId}" \
  --output table

# 2. Query Security Group rules for the discovered instances
SG_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" \
  --output text | tr '\t' '\n' | sort -u)

for SG_ID in $SG_IDS; do
    SG_NAME=$(aws ec2 describe-security-groups --group-ids $SG_ID --query "SecurityGroups[0].GroupName" --output text)
    echo -e "\n--- Security Group Rules for: $SG_NAME ($SG_ID) ---"
    aws ec2 describe-security-group-rules \
      --filters "Name=group-id,Values=$SG_ID" \
      --query "SecurityGroupRules[*].{RuleID:SecurityGroupRuleId, Direction:IsEgress, Protocol:IpProtocol, FromPort:FromPort, ToPort:ToPort, CIDR:CidrIpv4, SG_Source:ReferencedGroupInfo.GroupId}" \
      --output table
done

echo -e "\n🎯 Validation Task:"
echo "Confirm Port 80 Inbound references the ALB Security Group ID, NOT 0.0.0.0/0."
