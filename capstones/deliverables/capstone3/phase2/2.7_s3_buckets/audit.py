import boto3
import json
from datetime import datetime
from botocore.exceptions import ClientError

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
    sg_paginator = ec2_client.get_paginator('describe_security_groups')

    # Discovery Storage
    data = {
        "discovery_timestamp": datetime.now().isoformat(),
        "region": REGION,
        "dev": {},
        "prod": {},
        "tfstate_bucket": {}
    }

    def init_env():
        return {
            "vpc": {}, 
            "subnets": {}, 
            "route_tables": {}, 
            "security_groups": {},
            "ec2": {}, 
            "alb": {}, 
            "nlb": {}, 
            "s3": {}
        }

    data["dev"] = init_env()
    data["prod"] = init_env()

    # 1. Audit VPCs, IGWs, and NATs
    filters = [{'Name': 'tag:Project', 'Values': [PROJECT_TAG]}]
    for page in vpc_paginator.paginate(Filters=filters):
        for vpc in page['Vpcs']:
            vpc_id = vpc['VpcId']
            tags = vpc.get('Tags', [])
            env = (get_tag(tags, 'Environment') or 'dev').lower()
            
            # DNS Attributes
            dns_support = ec2_client.describe_vpc_attribute(VpcId=vpc_id, Attribute='enableDnsSupport')['EnableDnsSupport']['Value']
            dns_hostnames = ec2_client.describe_vpc_attribute(VpcId=vpc_id, Attribute='enableDnsHostnames')['EnableDnsHostnames']['Value']

            # Find IGW
            igws = ec2_client.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
            
            # Find NAT
            nats = ec2_client.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'state', 'Values': ['available']}])['NatGateways']
            nat_info = None
            if nats:
                nat = nats[0]
                nat_info = {
                    "id": nat['NatGatewayId'],
                    "name": get_tag(nat.get('Tags'), 'Name'),
                    "eip_allocation_id": nat['NatGatewayAddresses'][0].get('AllocationId'),
                    "public_ip": nat['NatGatewayAddresses'][0].get('PublicIp')
                }

            data[env]["vpc"] = {
                "id": vpc_id,
                "name": get_tag(tags, 'Name'),
                "cidr": vpc['CidrBlock'],
                "enable_dns_support": dns_support,
                "enable_dns_hostnames": dns_hostnames,
                "igw_id": igws[0]['InternetGatewayId'] if igws else None,
                "nat_gateway": nat_info
            }

    # 2. Audit Subnets
    for page in subnet_paginator.paginate(Filters=filters):
        for sub in page['Subnets']:
            tags = sub.get('Tags', [])
            env = (get_tag(tags, 'Environment') or 'dev').lower()
            name = get_tag(tags, 'Name')
            
            # Map logic to friendly keys if possible, or just use name
            key = name.replace(f"{env}-", "") if name else sub['SubnetId']
            
            data[env]["subnets"][key] = {
                "id": sub['SubnetId'],
                "name": name,
                "cidr": sub['CidrBlock'],
                "az": sub['AvailabilityZone'],
                "az_id": sub.get('AvailabilityZoneId'),
                "map_public_ip_on_launch": sub.get('MapPublicIpOnLaunch', False)
            }

    # 3. Audit Route Tables
    for page in rt_paginator.paginate(Filters=filters):
        for rt in page['RouteTables']:
            tags = rt.get('Tags', [])
            env = (get_tag(tags, 'Environment') or 'dev').lower()
            name = get_tag(tags, 'Name')
            
            routes = []
            for r in rt['Routes']:
                routes.append({
                    "destination": r.get('DestinationCidrBlock'),
                    "target": r.get('GatewayId') or r.get('NatGatewayId') or r.get('NetworkInterfaceId') or 'local',
                    "state": r.get('State')
                })
            
            associations = [a['SubnetId'] for a in rt.get('Associations', []) if 'SubnetId' in a]
            
            key = name.replace(f"{env}-", "") if name else rt['RouteTableId']
            data[env]["route_tables"][key] = {
                "id": rt['RouteTableId'],
                "name": name,
                "routes": routes,
                "associations": associations
            }

    # 4. Audit Security Groups (CRITICAL: Inbound & Outbound)
    for page in sg_paginator.paginate(Filters=filters):
        for sg in page['SecurityGroups']:
            tags = sg.get('Tags', [])
            env = (get_tag(tags, 'Environment') or 'dev').lower()
            sg_id = sg['GroupId']
            sg_name = sg['GroupName']
            
            ingress = []
            egress = []
            
            # Use describe_security_group_rules for detailed rule objects if available
            try:
                rules = ec2_client.describe_security_group_rules(Filters=[{'Name': 'group-id', 'Values': [sg_id]}])['SecurityGroupRules']
                for rule in rules:
                    rule_data = {
                        "id": rule['SecurityGroupRuleId'],
                        "protocol": rule['IpProtocol'],
                        "from_port": rule.get('FromPort'),
                        "to_port": rule.get('ToPort'),
                        "description": rule.get('Description'),
                        "source_cidr": rule.get('CidrIpv4'),
                        "source_sg": rule.get('ReferencedGroupInfo', {}).get('GroupId')
                    }
                    if rule.get('IsEgress'):
                        egress.append(rule_data)
                    else:
                        ingress.append(rule_data)
            except:
                # Fallback to old IpPermissions style if rules API fails
                for perm in sg.get('IpPermissions', []):
                    ingress.append(perm)
                for perm in sg.get('IpPermissionsEgress', []):
                    egress.append(perm)

            data[env]["security_groups"][sg_name] = {
                "id": sg_id,
                "description": sg['Description'],
                "ingress_rules": ingress,
                "egress_rules": egress
            }

    # 5. Audit EC2
    for page in instance_paginator.paginate(Filters=filters):
        for res in page['Reservations']:
            for i in res['Instances']:
                if i['State']['Name'] not in ['running', 'pending']: continue
                tags = i.get('Tags', [])
                env = (get_tag(tags, 'Environment') or 'dev').lower()
                
                data[env]["ec2"][get_tag(tags, 'Name') or 'web'] = {
                    "id": i['InstanceId'],
                    "ami": i['ImageId'],
                    "type": i['InstanceType'],
                    "private_ip": i.get('PrivateIpAddress'),
                    "public_ip": i.get('PublicIpAddress'),
                    "subnet_id": i['SubnetId'],
                    "security_groups": [sg['GroupId'] for sg in i['SecurityGroups']],
                    "key_name": i.get('KeyName')
                }

    # 6. Audit Load Balancers (ALB & NLB)
    lbs = elbv2_client.describe_load_balancers()['LoadBalancers']
    for lb in lbs:
        if PROJECT_TAG not in lb['LoadBalancerName']: continue
        env = 'dev' if 'dev' in lb['LoadBalancerName'].lower() else 'prod'
        lb_arn = lb['LoadBalancerArn']
        lb_type = lb['Type']

        # Get Listeners
        lb_listeners = []
        listeners = elbv2_client.describe_listeners(LoadBalancerArn=lb_arn)['Listeners']
        for l in listeners:
            lb_listeners.append({
                "arn": l['ListenerArn'],
                "port": l['Port'],
                "protocol": l['Protocol'],
                "default_actions": l['DefaultActions']
            })

        # Get Target Groups and their detailed Health Configs
        tg_data = {}
        tgs = elbv2_client.describe_target_groups(LoadBalancerArn=lb_arn)['TargetGroups']
        for tg in tgs:
            tg_arn = tg['TargetGroupArn']
            health_desc = elbv2_client.describe_target_health(TargetGroupArn=tg_arn)['TargetHealthDescriptions']
            
            tg_data[tg['TargetGroupName']] = {
                "arn": tg_arn,
                "port": tg['Port'],
                "protocol": tg['Protocol'],
                "target_type": tg['TargetType'],
                "health_check": {
                    "path": tg.get('HealthCheckPath'),
                    "interval": tg.get('HealthCheckIntervalSeconds'),
                    "timeout": tg.get('HealthCheckTimeoutSeconds'),
                    "healthy_threshold": tg.get('HealthyThresholdCount'),
                    "unhealthy_threshold": tg.get('UnhealthyThresholdCount'),
                    "matcher": tg.get('Matcher', {}).get('HttpCode')
                },
                "targets": [{"id": h['Target']['Id'], "health": h['TargetHealth']['State']} for h in health_desc]
            }

        lb_info = {
            "name": lb['LoadBalancerName'],
            "arn": lb_arn,
            "dns": lb['DNSName'],
            "vpc_id": lb['VpcId'],
            "scheme": lb['Scheme'],
            "subnets": [az['SubnetId'] for az in lb['AvailabilityZones']],
            "listeners": lb_listeners,
            "target_groups": tg_data
        }

        if lb_type == 'application':
            lb_info["security_groups"] = lb.get('SecurityGroups', [])
            data[env]["alb"] = lb_info
        else:
            lb_info["eip_allocation_ids"] = [addr.get('AllocationId') for az in lb['AvailabilityZones'] for addr in az.get('LoadBalancerAddresses', []) if 'AllocationId' in addr]
            data[env]["nlb"] = lb_info

    # 7. Audit S3 Buckets
    buckets = s3_client.list_buckets()['Buckets']
    for b in buckets:
        name = b['Name']
        if PROJECT_TAG not in name: continue
        
        # Tags for S3
        try:
            s3_tags = s3_client.get_bucket_tagging(Bucket=name)['TagSet']
            env = (get_tag(s3_tags, 'Environment') or 'dev').lower()
        except ClientError:
            env = 'dev' if 'dev' in name else 'prod'

        sse = versioning = pab = None
        try: sse = s3_client.get_bucket_encryption(Bucket=name)['ServerSideEncryptionConfiguration']['Rules'][0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm']
        except: pass
        try: versioning = s3_client.get_bucket_versioning(Bucket=name).get('Status') == 'Enabled'
        except: pass
        try: pab = s3_client.get_public_access_block(Bucket=name)['PublicAccessBlockConfiguration']
        except: pass

        s_data = {"name": name, "arn": f"arn:aws:s3:::{name}", "sse": sse, "versioning": versioning, "public_access_block": pab}
        
        if "tfstate" in name: data["tfstate_bucket"] = s_data
        elif "prod" in name: data["prod"]["s3"][name] = s_data
        else: data["dev"]["s3"][name] = s_data

    # Final Output
    with open('discovery.json', 'w') as f:
        json.dump(data, f, indent=2)
    
    print("\n" + "="*60)
    print(f"✅ Master Discovery JSON updated: {len(data['dev']['subnets']) + len(data['prod']['subnets'])} subnets found")
    print(f"✅ Security Group Inbound/Outbound rules captured!")
    print(f"✅ Load Balancer health check configurations captured!")
    print("="*60 + "\n")

if __name__ == "__main__":
    get_resources()


