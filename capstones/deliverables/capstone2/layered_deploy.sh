#!/bin/bash
# layered_deploy.sh — Simulates a CI/CD layered deployment (Dev -> Smoke Test -> Prod)

set -e # Exit on any error

# Use Environment Variable to force non-interactive mode (avoids flag parsing issues)
export TERRAGRUNT_NON_INTERACTIVE=true

echo "🚀 Starting Stage 1: Deploying to DEV..."
cd infrastructure/dev
terragrunt run -all apply --non-interactive

echo "🔍 Starting Stage 2: Smoke Testing DEV instances..."
# Substitute real ALB/instance verification
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "❌ Error: No running dev instances found."
  exit 1
fi

STATE=$(aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --query "InstanceStatuses[0].InstanceState.Name" --output text 2>/dev/null || echo "pending")

echo "Dev instance ($INSTANCE_ID) state: $STATE"

echo "🏁 Starting Stage 3: Decision Gate..."
if [ "$STATE" = "running" ]; then
  echo "✅ Dev smoke test passed. Promoting to PROD..."
  cd ../prod
  terragrunt run -all apply --non-interactive
else
  echo "❌ Dev smoke test failed. Halting PROD deployment."
  exit 1
fi
