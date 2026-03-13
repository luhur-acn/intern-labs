#!/bin/bash
# 2.6_s3_buckets/discovery.sh

echo "🔍 Step 2.6: Listing all project buckets..."
BUCKETS=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'capstone')].Name" --output text)

aws s3api list-buckets \
  --query "Buckets[?contains(Name, 'capstone')].{Name:Name, Created:CreationDate}" \
  --output table

for BUCKET in $BUCKETS; do
    echo -e "\n--- Audit for Bucket: $BUCKET ---"
    
    echo "[Encryption]"
    aws s3api get-bucket-encryption --bucket $BUCKET \
      --query "ServerSideEncryptionConfiguration.Rules[*].ApplyServerSideEncryptionByDefault.{Algorithm:SSEAlgorithm}" \
      --output table || echo "No Encryption Found"

    echo "[Versioning]"
    aws s3api get-bucket-versioning --bucket $BUCKET --output table || echo "Versioning Disabled"

    echo "[Public Access Block]"
    aws s3api get-public-access-block --bucket $BUCKET --output table || echo "No Public Access Block Found"
done

echo -e "\n🎯 Validation Task:"
echo "Confirm Encryption=AES256, Versioning=Enabled, and PublicAccessBlock=True."
