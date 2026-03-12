#!/bin/bash

# convert_plans.sh
# Script to convert existing binary 'tfplan' files to 'plan.txt' across all modules

echo "🚀 Converting existing binary 'tfplan' files to 'plan.txt'..."

# List of all modules in both environments
MODULES=(
    "dev/vpc" "dev/subnets" "dev/security-groups" "dev/ec2" "dev/alb" "dev/nlb" "dev/s3"
    "prod/vpc" "prod/subnets" "prod/security-groups" "prod/ec2" "prod/alb" "prod/nlb" "prod/s3"
)

for dir in "${MODULES[@]}"; do
    if [ -d "$dir" ]; then
        if [ -f "$dir/tfplan" ]; then
            echo "----------------------------------------------------------"
            echo "📂 Processing: $dir"
            
            # Move into the directory
            pushd "$dir" > /dev/null

            # Convert binary 'tfplan' to human-readable 'plan.txt'
            echo "   -> Converting binary tfplan to plan.txt..."
            terragrunt show -no-color tfplan > plan.txt

            # Verify the output
            if grep -q "No changes." plan.txt || grep -q "0 to add, 0 to change, 0 to destroy" plan.txt; then
                echo "   ✅ SUCCESS: No changes detected."
            else
                echo "   ⚠️ DRIFT: Changes found in $dir/plan.txt"
            fi

            # Return to the previous directory
            popd > /dev/null
        else
            echo "⏩ Skipping $dir: No 'tfplan' file found."
        fi
    fi
done

echo "----------------------------------------------------------"
echo "✅ Done! Conversion complete."
