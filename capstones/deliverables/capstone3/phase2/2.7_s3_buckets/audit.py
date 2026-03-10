import boto3
import json
from datetime import datetime

REGION = "us-east-1"
PROJECT_TAG = "capstone"

ec2_client = boto3.client('ec2', region_name=REGION)
elbv2_client = boto3.client('elbv2', region_name=REGION)
s3_client = boto3.client('s3', region_name=REGION)

def get_tag(tags, key):
    if not tags: return None
    return next((t['Value'] for t in tags if t['Key'] == key), None)

def get_resources():
    # Setup Paginators
    vpc_paginator = ec2_client.get_paginator('describe_vpcs')
    subnet_paginator = ec2_client.get_paginator('describe_subnets')
    instance_paginator = ec2_client.get_paginator('describe_instances')
    rt_paginator = ec2_client.get_paginator('describe_route_tables')

    # Filter resources by Project Tag
    filters = [{'Name': 'tag:Project', 'Values': [PROJECT_TAG]}]
    
    # Discovery Storage
    data = {
        "discovery_timestamp": datetime.now().isoformat(),
        "region": REGION,
        "dev": {},
        "prod": {},
        "tfstate_bucket": {}
    }

    # Helper to initialize env structure
    def init_env():
        return {"vpc": {}, "subnets": [], "route_tables": [], "ec2": {}, "alb": {}, "nlb": {}, "s3": {}}

    data["dev"] = init_env()
    data["prod"] = init_env()

    # 1. Audit VPCs, IGWs, and NATs
    for page in vpc_paginator.paginate(Filters=filters):
        for vpc in page['Vpcs']:
            vpc_id = vpc['VpcId']
            env = get_tag(vpc.get('Tags'), 'Environment') or 'dev'
            
            # Find IGW
            igws = ec2_client.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
            # Find NAT
            nats = ec2_client.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'state', 'Values': ['available']}])['NatGateways']
            
            data[env.lower()]["vpc"] = {
                "id": vpc_id,
                "cidr": vpc['CidrBlock'],
                "igw_id": igws[0]['InternetGatewayId'] if igws else None,
                "nat_gateway_id": nats[0]['NatGatewayId'] if nats else None
            }

    # 2. Audit Subnets
    for page in subnet_paginator.paginate(Filters=filters):
        for sub in page['Subnets']:
            env = get_tag(sub.get('Tags'), 'Environment') or 'dev'
            data[env.lower()]["subnets"].append({
                "id": sub['SubnetId'],
                "cidr": sub['CidrBlock'],
                "type": "public" if sub.get('MapPublicIpOnLaunch') else "private",
                "az": sub['AvailabilityZone'],
                "name": get_tag(sub.get('Tags'), 'Name')
            })

    # 3. Audit Route Tables
    for page in rt_paginator.paginate(Filters=filters):
        for rt in page['RouteTables']:
            env = get_tag(rt.get('Tags'), 'Environment') or 'dev'
            routes = []
            is_public = False
            for r in rt['Routes']:
                target = r.get('GatewayId') or r.get('NatGatewayId') or r.get('LocalGatewayId', 'local')
                if str(target).startswith('igw-'): is_public = True
                routes.append({"dest": r.get('DestinationCidrBlock'), "target": target})
            
            data[env.lower()]["route_tables"].append({
                "id": rt['RouteTableId'],
                "type": "public" if is_public else "private",
                "routes": routes
            })

    # 4. Audit EC2 & resolve Security Groups
    for page in instance_paginator.paginate(Filters=filters):
        for res in page['Reservations']:
            for i in res['Instances']:
                if i['State']['Name'] != 'running': continue
                env = get_tag(i.get('Tags'), 'Environment') or 'dev'
                sg_id = i['SecurityGroups'][0]['GroupId']
                
                # Resolve SG Rules
                sg_rules = ec2_client.describe_security_group_rules(Filters=[{'Name': 'group-id', 'Values': [sg_id]}])['SecurityGroupRules']
                rules_audit = []
                for rule in sg_rules:
                    if not rule.get('IsEgress'):
                        rules_audit.append({
                            "port": rule.get('FromPort'),
                            "source_sg": rule.get('ReferencedGroupInfo', {}).get('GroupId'),
                            "source_cidr": rule.get('CidrIpv4')
                        })

                data[env.lower()]["ec2"] = {
                    "id": i['InstanceId'],
                    "private_ip": i.get('PrivateIpAddress'),
                    "security_group_id": sg_id,
                    "inbound_rules": rules_audit
                }

    # 5. Audit Load Balancers (ALB & NLB) and Target health
    lbs = elbv2_client.describe_load_balancers()['LoadBalancers']
    for lb in lbs:
        if PROJECT_TAG not in lb['LoadBalancerName']: continue
        env = 'dev' if 'dev' in lb['LoadBalancerName'].lower() else 'prod'
        lb_type = lb['Type']
        lb_arn = lb['LoadBalancerArn']

        # Get Target Health
        tgs = elbv2_client.describe_target_groups(LoadBalancerArn=lb_arn)['TargetGroups']
        tg_arn = tgs[0]['TargetGroupArn'] if tgs else None
        health = "unknown"
        if tg_arn:
            health_desc = elbv2_client.describe_target_health(TargetGroupArn=tg_arn)['TargetHealthDescriptions']
            health = "healthy" if all(h['TargetHealth']['State'] == 'healthy' for h in health_desc) else "unhealthy"

        lb_data = {
            "arn": lb_arn,
            "dns": lb['DNSName'],
            "target_group_arn": tg_arn,
            "target_health": health
        }

        if lb_type == 'application':
            listeners = elbv2_client.describe_listeners(LoadBalancerArn=lb_arn)['Listeners']
            lb_data["listener_arn"] = listeners[0]['ListenerArn'] if listeners else None
            data[env]["alb"] = lb_data
        else:
            # For NLB, find EIP
            addr = ec2_client.describe_addresses(Filters=[{'Name': 'network-interface-id', 'Values': [lb.get('AvailabilityZones', [{}])[0].get('LoadBalancerAddresses', [{}])[0].get('AllocationId', 'none')]}])
            lb_data["eip_allocation_id"] = lb.get('AvailabilityZones', [{}])[0].get('LoadBalancerAddresses', [{}])[0].get('AllocationId')
            data[env]["nlb"] = lb_data

    # 6. Audit S3 Buckets
    buckets = s3_client.list_buckets()['Buckets']
    for b in buckets:
        name = b['Name']
        if PROJECT_TAG not in name: continue
        
        # Check security
        try:
            s3_client.get_bucket_encryption(Bucket=name)
            encrypted = True
        except: encrypted = False
        
        try:
            ver = s3_client.get_bucket_versioning(Bucket=name)
            versioning = ver.get('Status') == 'Enabled'
        except: versioning = False

        s_data = {"name": name, "arn": f"arn:aws:s3:::{name}", "encrypted": encrypted, "versioning": versioning}
        
        if "tfstate" in name:
            data["tfstate_bucket"] = s_data
        elif "prod" in name:
            data["prod"]["s3"] = s_data
        else:
            data["dev"]["s3"] = s_data

    # Final Output
    with open('discovery.json', 'w') as f:
        json.dump(data, f, indent=2)
    print("🚀 Master Discovery JSON generated successfully!")

if __name__ == "__main__":
    get_resources()
