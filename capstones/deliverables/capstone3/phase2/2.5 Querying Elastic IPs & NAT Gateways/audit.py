# 2.5_gateways/audit.py
import boto3, json

ec2 = boto3.client('ec2', region_name='us-east-1')

def audit_gateways():
    print("🕵️  Auditing NAT Gateways, EIPs, and Subnet placement...")
    
    # Get all project subnets for cross-referencing
    subnets = ec2.describe_subnets(Filters=[{'Name': 'tag:Project', 'Values': ['capstone']}])['Subnets']
    sub_map = {s['SubnetId']: next((t['Value'] for t in s.get('Tags', []) if t['Key'] == 'Name'), "unnamed") for s in subnets}

    # Get project NAT Gateways
    nats = ec2.describe_nat_gateways(Filters=[{'Name': 'tag:Project', 'Values': ['capstone']}])['NatGateways']
    
    discovery_data = []

    for n in nats:
        nat_id = n['NatGatewayId']
        sub_id = n['SubnetId']
        sub_name = sub_map.get(sub_id, "Unknown/External Subnet")
        
        # Get EIP details linked to this NAT
        nat_addresses = n.get('NatGatewayAddresses', [])
        eip_details = []
        for addr in nat_addresses:
            alloc_id = addr.get('AllocationId')
            # Verify EIP association via describe-addresses
            eip_info = ec2.describe_addresses(AllocationIds=[alloc_id])['Addresses'][0]
            
            eip_details.append({
                "PublicIp": addr.get('PublicIp'),
                "AllocationId": alloc_id,
                "AssociationId": eip_info.get('AssociationId'),
                "NetworkInterfaceId": addr.get('NetworkInterfaceId'),
                "IsCorrectlyAssociated": eip_info.get('NetworkInterfaceId') == addr.get('NetworkInterfaceId')
            })

        # Validation: NAT should be in a public subnet
        is_in_public = "public" in sub_name.lower()
        
        discovery_data.append({
            "NatGatewayId": nat_id,
            "State": n['State'],
            "SubnetId": sub_id,
            "SubnetName": sub_name,
            "ElasticIPDetails": eip_details,
            "Validation": {
                "InPublicSubnet": is_in_public,
                "EIPAssociatedToNATInterface": all(e['IsCorrectlyAssociated'] for e in eip_details),
                "Discrepancy": None if is_in_public else f"NAT Gateway is in a non-public subnet: {sub_name}"
            }
        })

    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    print("✅ 2.5 discovery.json generated with EIP & Interface validation.")

if __name__ == "__main__":
    audit_gateways()
