# 2.6_s3_buckets/audit.py
import boto3, json, sys

s3 = boto3.client('s3', region_name='us-east-1')

def audit_s3_buckets():
    print("🕵️  Auditing S3 Buckets and Compliance...")
    try:
        buckets = s3.list_buckets()['Buckets']
    except Exception as e:
        print(f"❌ Error listing buckets: {e}")
        return

    discovery_data = []

    for b in buckets:
        name = b['Name']
        if 'capstone' in name:
            # 1. Audit Encryption
            try:
                enc = s3.get_bucket_encryption(Bucket=name)
                algorithm = enc['ServerSideEncryptionConfiguration']['Rules'][0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
                encryption_ok = algorithm == 'AES256'
            except:
                algorithm = "None"
                encryption_ok = False

            # 2. Audit Versioning
            versioning = s3.get_bucket_versioning(Bucket=name)
            ver_status = versioning.get('Status', 'Disabled')
            versioning_ok = ver_status == 'Enabled'

            # 3. Audit Public Access Block
            try:
                pab = s3.get_public_access_block(Bucket=name)['PublicAccessBlockConfiguration']
                block_all = all([pab['BlockPublicAcls'], pab['IgnorePublicAcls'], pab['BlockPublicPolicy'], pab['RestrictPublicBuckets']])
            except:
                block_all = False

            discovery_data.append({
                "BucketName": name,
                "Audit": {
                    "Encryption": algorithm,
                    "Versioning": ver_status,
                    "PublicAccessBlocked": block_all
                },
                "Compliance": {
                    "Overall": all([encryption_ok, versioning_ok, block_all]),
                    "Discrepancy": None if all([encryption_ok, versioning_ok, block_all]) else "Security findings detected!"
                }
            })

    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    print("✅ 2.6 discovery.json generated with S3 Compliance table.")

if __name__ == "__main__":
    audit_s3_buckets()
