# 2.2_subnets/audit.py
import boto3, json

ec2 = boto3.client('ec2', region_name='us-east-1')

def audit_subnets():
    print("🕵️  Auditing Subnets and Public IP settings...")
    subs = ec2.describe_subnets(Filters=[{'Name': 'tag:Project', 'Values': ['capstone']}])['Subnets']

    inventory = []
    for s in subs:
        name = next((t['Value'] for t in s.get('Tags', []) if t['Key'] == 'Name'), "unnamed")
        auto_public = s.get('MapPublicIpOnLaunch', False)
        
        # Validation Logic
        is_public_by_name = "public" in name.lower()
        discrepancy = None
        
        if is_public_by_name and not auto_public:
            discrepancy = "Public subnet has MapPublicIpOnLaunch=False"
        elif not is_public_by_name and auto_public:
            discrepancy = "Private subnet has MapPublicIpOnLaunch=True"

        inventory.append({
            "SubnetId": s['SubnetId'],
            "Cidr": s['CidrBlock'],
            "AZ": s['AvailabilityZone'],
            "Name": name,
            "AutoPublicIP": auto_public,
            "Discrepancy": discrepancy
        })

    with open('discovery.json', 'w') as f:
        json.dump(inventory, f, indent=4)
    print("✅ 2.2 discovery.json generated with AutoPublicIP validation.")

if __name__ == "__main__":
    audit_subnets()
