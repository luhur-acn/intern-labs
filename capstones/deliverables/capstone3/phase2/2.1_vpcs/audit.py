# 2.1_vpcs/audit.py
import boto3, json, sys

ec2 = boto3.client('ec2', region_name='us-east-1')

def audit_vpcs():
    print("🕵️  Auditing VPCs, IGWs, and Route Tables...")
    try:
        vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Project', 'Values': ['capstone']}])['Vpcs']
    except Exception as e:
        print(f"❌ Failed to reach AWS: {e}")
        return

    discovery_data = []

    for vpc in vpcs:
        vpc_id = vpc['VpcId']
        vpc_name = next((t['Value'] for t in vpc.get('Tags', []) if t['Key'] == 'Name'), "unnamed")
        
        # Discover IGW
        igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
        igw_id = igws[0]['InternetGatewayId'] if igws else None

        # Discover Route Tables
        rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['RouteTables']
        route_tables = []
        
        for rt in rts:
            routes = rt.get('Routes', [])
            
            # IMPROVED LOGIC: Check for IGW and NAT in all standard fields
            has_igw_route = any(r.get('GatewayId', '').startswith('igw-') for r in routes)
            has_nat_route = any(
                r.get('NatGatewayId') is not None or 
                r.get('GatewayId', '').startswith('nat-') 
                for r in routes
            )
            
            rt_type = "Public" if has_igw_route else "Private"
            
            # Discrepancy detection
            discrepancy = None
            if rt_type == "Public" and not has_igw_route:
                discrepancy = "Public RT missing IGW route"
            elif rt_type == "Private" and not has_nat_route:
                # If it's unnamed AND has no NAT, it's likely the default Main RT
                rt_name = next((t['Value'] for t in rt.get('Tags', []) if t['Key'] == 'Name'), "unnamed")
                if rt_name == "unnamed":
                    discrepancy = "Main/Unnamed RT (no NAT route by default)"
                else:
                    discrepancy = "Private RT missing NAT Gateway route"

            route_tables.append({
                "RouteTableId": rt['RouteTableId'],
                "Name": next((t['Value'] for t in rt.get('Tags', []) if t['Key'] == 'Name'), "unnamed"),
                "Type": rt_type,
                "HasIGW": has_igw_route,
                "HasNAT": has_nat_route,
                "Discrepancy": discrepancy
            })

        discovery_data.append({
            "VpcId": vpc_id,
            "VpcName": vpc_name,
            "CidrBlock": vpc['CidrBlock'],
            "IgwId": igw_id,
            "RouteTables": route_tables
        })

    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    print("✅ 2.1 discovery.json generated with deep audit data.")

if __name__ == "__main__":
    audit_vpcs()
