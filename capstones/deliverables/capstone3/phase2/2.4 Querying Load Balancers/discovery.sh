#!/bin/bash
# 2.4_load_balancers/discovery.sh

echo "🔍 Step 2.4: Discovering Application Load Balancers (ALB)..."
ALB_ARNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Type=='application' && contains(LoadBalancerName, 'capstone')].LoadBalancerArn" \
  --output text)

aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Type=='application' && contains(LoadBalancerName, 'capstone')].{Name:LoadBalancerName, ARN:LoadBalancerArn, DNS:DNSName, State:State.Code, Scheme:Scheme}" \
  --output table

# NEW: CLI Task — Get the listeners for each ALB
for ALB_ARN in $ALB_ARNS; do
    echo -e "\n👂 Listeners for ALB: $(echo $ALB_ARN | cut -d'/' -f3)"
    aws elbv2 describe-listeners \
      --load-balancer-arn "$ALB_ARN" \
      --query "Listeners[*].{ARN:ListenerArn, Port:Port, Protocol:Protocol, DefaultAction:DefaultActions[0].Type, TargetGroup:DefaultActions[0].TargetGroupArn}" \
      --output table
done

echo -e "\n🔍 Step 2.4: Discovering Network Load Balancers (NLB)..."
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Type=='network' && contains(LoadBalancerName, 'capstone')].{Name:LoadBalancerName, ARN:LoadBalancerArn, DNS:DNSName, State:State.Code}" \
  --output table

# NEW: CLI Task — List all Target Groups Summary
echo -e "\n🎯 Target Groups Summary:"
aws elbv2 describe-target-groups \
  --query "TargetGroups[?contains(TargetGroupName, 'capstone')].{Name:TargetGroupName, ARN:TargetGroupArn, Type:TargetType, Protocol:Protocol, Port:Port}" \
  --output table

# CLI Task — Query Target Group health and target registration
echo -e "\n🩺 Checking Target Group Health Details..."
TG_ARNS=$(aws elbv2 describe-target-groups \
  --query "TargetGroups[?contains(TargetGroupName, 'capstone')].TargetGroupArn" \
  --output text)

for TG_ARN in $TG_ARNS; do
    TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns $TG_ARN --query "TargetGroups[0].TargetGroupName" --output text)
    echo -e "\n--- Health Status for: $TG_NAME ---"
    aws elbv2 describe-target-health \
      --target-group-arn "$TG_ARN" \
      --query "TargetHealthDescriptions[*].{Target:Target.Id, Port:Target.Port, Health:TargetHealth.State, Reason:TargetHealth.Reason}" \
      --output table
done

echo -e "\n🎯 Validation Task:"
echo "All EC2 targets must be 'healthy' before proceeding to Phase 3."
