#!/bin/bash

# Configuration
BUCKET_NAME="iac-capstone-tfstate-justo"
REGION="us-east-1"

echo "[1/3] Creating S3 Bucket: ${BUCKET_NAME}..."
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"

if [ $? -ne 0 ]; then
    echo "Note: If there was an error, the bucket might already exist or the name is taken."
fi

echo "[2/3] Enabling Versioning..."
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled

echo "[3/3] Enabling Server-Side Encryption..."
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'

echo ""
echo "============================================"
echo "Setup Complete for Justo!"
echo "Bucket: ${BUCKET_NAME}"
echo "Locking: Using S3 Native Locking (use_lockfile)"
echo "============================================"
