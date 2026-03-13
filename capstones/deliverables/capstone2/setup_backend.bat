@echo off
SET BUCKET_NAME=iac-capstone-tfstate-justo
SET REGION=us-east-1

echo [1/3] Creating S3 Bucket: %BUCKET_NAME%...
aws s3api create-bucket --bucket %BUCKET_NAME% --region %REGION%
if %ERRORLEVEL% NEQ 0 (
    echo Error creating bucket. It might already exist or name is taken.
)

echo [2/3] Enabling Versioning...
aws s3api put-bucket-versioning --bucket %BUCKET_NAME% --versioning-configuration Status=Enabled

echo [3/3] Enabling Server-Side Encryption...
aws s3api put-bucket-encryption --bucket %BUCKET_NAME% --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"

echo.
echo ============================================
echo Setup Complete for Justo!
echo Bucket: %BUCKET_NAME%
echo Locking: Using S3 Native Locking (use_lockfile)
echo ============================================
pause
