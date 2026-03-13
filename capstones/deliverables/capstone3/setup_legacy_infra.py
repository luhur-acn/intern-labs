import boto3
import time
import random
import string
import sys
import json
import os
from botocore.exceptions import ClientError

# Configuration
REGION = "us-east-1"
YOUR_NAME = "justo"
PROJECT = "capstone"

ec2 = boto3.client('ec2', region_name=REGION)
elbv2 = boto3.client('elbv2', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

# Discovery storage
discovery_data = {
    "dev": {},
    "prod": {},
    "storage": {}
}

def get_random_string(length=6):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def get_vpc_by_name(name):
    vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': [name]}])['Vpcs']
    return vpcs[0]['VpcId'] if vpcs else None

def wait_for_nat_gw(nat_gw_id):
    print(f"⌛ Waiting for NAT Gateway {nat_gw_id} to be available...")
    waiter = ec2.get_waiter('nat_gateway_available')
    waiter.wait(NatGatewayIds=[nat_gw_id])
    print(f"✅ NAT Gateway {nat_gw_id} is ready.")

def wait_for_alb(alb_arn):
    print(f"⌛ Waiting for ALB to be ACTIVE (this takes ~3 mins)...")
    waiter = elbv2.get_waiter('load_balancer_available')
    waiter.wait(LoadBalancerArns=[alb_arn])
    print(f"✅ ALB is ACTIVE.")

def create_tags(resource_id, name, env):
    ec2.create_tags(
        Resources=[resource_id],
        Tags=[
            {'Key': 'Name', 'Value': name},
            {'Key': 'Environment', 'Value': env},
            {'Key': 'Project', 'Value': PROJECT}
        ]
    )

def setup_environment(env, vpc_cidr, pub_a_cidr, pub_b_cidr, priv_a_cidr, priv_b_cidr):
    print(f"\n🚀 --- Building {env.upper()} Environment ---")
    data = {}
    
    try:
        # 1. VPC
        vpc_name = f"{env}-vpc"
        vpc_id = get_vpc_by_name(vpc_name)
        if not vpc_id:
            vpc = ec2.create_vpc(CidrBlock=vpc_cidr)
            vpc_id = vpc['Vpc']['VpcId']
            ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsSupport={'Value': True})
            ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsHostnames={'Value': True})
            create_tags(vpc_id, vpc_name, env)
            print(f"✅ Created VPC: {vpc_id}")
        else:
            print(f"⏩ VPC {vpc_id} already exists.")
        data['vpc_id'] = vpc_id
        data['vpc_cidr'] = vpc_cidr

        # 2. Internet Gateway
        igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
        if not igws:
            igw = ec2.create_internet_gateway()
            igw_id = igw['InternetGateway']['InternetGatewayId']
            ec2.attach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
            create_tags(igw_id, f"{env}-igw", env)
            print(f"✅ Created IGW: {igw_id}")
        else:
            igw_id = igws[0]['InternetGatewayId']
            print(f"⏩ IGW {igw_id} exists.")
        data['igw_id'] = igw_id

        # 3. Subnets
        def get_or_create_sub(cidr, az, name, is_public=False):
            subs = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'cidr-block', 'Values': [cidr]}])['Subnets']
            if subs:
                s_id = subs[0]['SubnetId']
                print(f"⏩ Subnet {name} ({cidr}) exists.")
            else:
                s_id = ec2.create_subnet(VpcId=vpc_id, CidrBlock=cidr, AvailabilityZone=az)['Subnet']['SubnetId']
                create_tags(s_id, name, env)
                print(f"✅ Created Subnet: {name}")
            
            if is_public:
                ec2.modify_subnet_attribute(SubnetId=s_id, MapPublicIpOnLaunch={'Value': True})
            return s_id

        data['subnets'] = {
            'public-a': get_or_create_sub(pub_a_cidr, f"{REGION}a", f"{env}-public-subnet-a", True),
            'public-b': get_or_create_sub(pub_b_cidr, f"{REGION}b", f"{env}-public-subnet-b", True),
            'private-a': get_or_create_sub(priv_a_cidr, f"{REGION}a", f"{env}-private-subnet-a", False),
            'private-b': get_or_create_sub(priv_b_cidr, f"{REGION}b", f"{env}-private-subnet-b", False)
        }

        # 4. NAT Gateway
        nats = ec2.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'state', 'Values': ['pending', 'available']}])['NatGateways']
        if not nats:
            eip_nat = ec2.allocate_address(Domain='vpc')
            eip_alloc_id = eip_nat['AllocationId']
            data['nat_eip_id'] = eip_alloc_id
            nat_gw = ec2.create_nat_gateway(SubnetId=data['subnets']['public-a'], AllocationId=eip_alloc_id)
            nat_gw_id = nat_gw['NatGateway']['NatGatewayId']
            create_tags(nat_gw_id, f"{env}-nat-gw", env)
            wait_for_nat_gw(nat_gw_id)
        else:
            nat_gw_id = nats[0]['NatGatewayId']
            eip_alloc_id = nats[0]['NatGatewayAddresses'][0]['AllocationId']
            print(f"⏩ NAT Gateway {nat_gw_id} exists.")
        
        data['nat_gw_id'] = nat_gw_id
        data['nat_eip_id'] = eip_alloc_id

        # 5. Route Tables
        def get_or_create_rt(name, target_id, is_igw=True):
            rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'tag:Name', 'Values': [name]}])['RouteTables']
            if rts:
                print(f"⏩ Route Table {name} exists.")
                return rts[0]['RouteTableId']
            rt = ec2.create_route_table(VpcId=vpc_id)['RouteTable']['RouteTableId']
            if is_igw:
                ec2.create_route(RouteTableId=rt, DestinationCidrBlock='0.0.0.0/0', GatewayId=target_id)
            else:
                ec2.create_route(RouteTableId=rt, DestinationCidrBlock='0.0.0.0/0', NatGatewayId=target_id)
            create_tags(rt, name, env)
            print(f"✅ Created RT: {name}")
            return rt

        data['route_tables'] = {
            'public': get_or_create_rt(f"{env}-public-rt", igw_id, True),
            'private': get_or_create_rt(f"{env}-private-rt", nat_gw_id, False)
        }
        
        # Associations
        for sub_key in ['public-a', 'public-b']:
            ec2.associate_route_table(RouteTableId=data['route_tables']['public'], SubnetId=data['subnets'][sub_key])
        for sub_key in ['private-a', 'private-b']:
            ec2.associate_route_table(RouteTableId=data['route_tables']['private'], SubnetId=data['subnets'][sub_key])

        # 6. Security Groups
        def get_or_create_sg(name, desc):
            sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'group-name', 'Values': [name]}])['SecurityGroups']
            if sgs:
                print(f"⏩ Security Group {name} exists.")
                return sgs[0]['GroupId']
            sg = ec2.create_security_group(GroupName=name, Description=desc, VpcId=vpc_id)['GroupId']
            create_tags(sg, name, env)
            print(f"✅ Created SG: {name}")
            return sg

        data['security_groups'] = {
            'alb': get_or_create_sg(f"capstone-{env}-alb-sg", f"ALB SG for {env}"),
            'ec2': get_or_create_sg(f"capstone-{env}-ec2-sg", f"EC2 SG for {env}")
        }

        # SG Rules Inbound
        try:
            ec2.authorize_security_group_ingress(GroupId=data['security_groups']['alb'], IpProtocol='tcp', FromPort=80, ToPort=80, CidrIp='0.0.0.0/0')
        except ClientError: pass

        try:
            ec2.authorize_security_group_ingress(
                GroupId=data['security_groups']['ec2'],
                IpPermissions=[
                    {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'UserIdGroupPairs': [{'GroupId': data['security_groups']['alb']}]},
                    {'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'IpRanges': [{'CidrIp': '10.0.0.0/8'}]}
                ]
            )
        except ClientError: pass

        # 7. EC2 Instance
        insts = ec2.describe_instances(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'tag:Name', 'Values': [f"web-{env}"]}, {'Name': 'instance-state-name', 'Values': ['running', 'pending']}])['Reservations']
        if not insts:
            user_data = f"#!/bin/bash\nyum update -y; yum install -y httpd\necho '<h1>Capstone {env.upper()} Server</h1>' > /var/www/html/index.html\nsystemctl start httpd; systemctl enable httpd"
            instance = ec2.run_instances(ImageId='ami-0c02fb55956c7d316', InstanceType='t3.micro', MinCount=1, MaxCount=1, SubnetId=data['subnets']['private-a'], SecurityGroupIds=[data['security_groups']['ec2']], UserData=user_data)['Instances'][0]
            instance_id = instance['InstanceId']
            create_tags(instance_id, f"web-{env}", env)
            print(f"✅ Created EC2: {instance_id}")
        else:
            instance = insts[0]['Instances'][0]
            instance_id = instance['InstanceId']
            print(f"⏩ EC2 Instance {instance_id} exists.")
        
        data['ec2'] = {
            'id': instance_id,
            'private_ip': instance.get('PrivateIpAddress', 'N/A')
        }

        # 8. ALB
        alb_name = f"capstone-{env}-alb"
        try:
            alb_info = elbv2.describe_load_balancers(Names=[alb_name])['LoadBalancers'][0]
            print(f"⏩ ALB {alb_name} exists.")
        except elbv2.exceptions.LoadBalancerNotFoundException:
            print("⌛ Creating ALB...")
            alb_info = elbv2.create_load_balancer(Name=alb_name, Subnets=[data['subnets']['public-a'], data['subnets']['public-b']], SecurityGroups=[data['security_groups']['alb']], Scheme='internet-facing', Type='application')['LoadBalancers'][0]
        
        data['alb'] = {
            'arn': alb_info['LoadBalancerArn'],
            'dns': alb_info['DNSName']
        }

        # ALB Target Group
        tg_name = f"capstone-{env}-ec2-tg"
        try:
            tg_info = elbv2.describe_target_groups(Names=[tg_name])['TargetGroups'][0]
            print(f"⏩ Target Group {tg_name} exists.")
        except elbv2.exceptions.TargetGroupNotFoundException:
            tg_info = elbv2.create_target_group(Name=tg_name, Protocol='HTTP', Port=80, VpcId=vpc_id, TargetType='instance')['TargetGroups'][0]
        
        data['alb']['target_group_arn'] = tg_info['TargetGroupArn']
        elbv2.register_targets(TargetGroupArn=tg_info['TargetGroupArn'], Targets=[{'Id': instance_id}])

        # ALB Listener
        listeners = elbv2.describe_listeners(LoadBalancerArn=data['alb']['arn'])['Listeners']
        if not listeners:
            ls = elbv2.create_listener(LoadBalancerArn=data['alb']['arn'], Protocol='HTTP', Port=80, DefaultActions=[{'Type': 'forward', 'TargetGroupArn': tg_info['TargetGroupArn']}])
            data['alb']['listener_arn'] = ls['Listeners'][0]['ListenerArn']
        else:
            data['alb']['listener_arn'] = listeners[0]['ListenerArn']

        # 9. NLB
        nlb_name = f"capstone-{env}-nlb"
        try:
            nlb_info = elbv2.describe_load_balancers(Names=[nlb_name])['LoadBalancers'][0]
            print(f"⏩ NLB {nlb_name} exists.")
        except elbv2.exceptions.LoadBalancerNotFoundException:
            wait_for_alb(data['alb']['arn'])
            eip_nlb = ec2.allocate_address(Domain='vpc')['AllocationId']
            data['nlb_eip_id'] = eip_nlb
            nlb_info = elbv2.create_load_balancer(Name=nlb_name, SubnetMappings=[{'SubnetId': data['subnets']['public-a'], 'AllocationId': eip_nlb}], Type='network', Scheme='internet-facing')['LoadBalancers'][0]
        
        data['nlb'] = {
            'arn': nlb_info['LoadBalancerArn'],
            'dns': nlb_info['DNSName']
        }

        # NLB Target Group (Forward to ALB)
        nlb_tg_name = f"capstone-{env}-alb-tg"
        try:
            tg_alb_info = elbv2.describe_target_groups(Names=[nlb_tg_name])['TargetGroups'][0]
            print(f"⏩ Target Group {nlb_tg_name} exists.")
        except elbv2.exceptions.TargetGroupNotFoundException:
            tg_alb_info = elbv2.create_target_group(Name=nlb_tg_name, Protocol='TCP', Port=80, VpcId=vpc_id, TargetType='alb')['TargetGroups'][0]
        
        data['nlb']['target_group_arn'] = tg_alb_info['TargetGroupArn']
        elbv2.register_targets(TargetGroupArn=tg_alb_info['TargetGroupArn'], Targets=[{'Id': data['alb']['arn']}])

        # NLB Listener
        listeners = elbv2.describe_listeners(LoadBalancerArn=data['nlb']['arn'])['Listeners']
        if not listeners:
            ls = elbv2.create_listener(LoadBalancerArn=data['nlb']['arn'], Protocol='TCP', Port=80, DefaultActions=[{'Type': 'forward', 'TargetGroupArn': tg_alb_info['TargetGroupArn']}])
            data['nlb']['listener_arn'] = ls['Listeners'][0]['ListenerArn']
        else:
            data['nlb']['listener_arn'] = listeners[0]['ListenerArn']

        discovery_data[env] = data

    except ClientError as e:
        print(f"❌ ERROR: {e}"); sys.exit(1)

def setup_s3(name):
    full_name_base = f"{name}-{YOUR_NAME}-"
    buckets = s3.list_buckets()['Buckets']
    exists = [b['Name'] for b in buckets if b['Name'].startswith(full_name_base)]
    if exists:
        bucket_name = exists[0]
        print(f"⏩ Bucket {bucket_name} exists.")
    else:
        bucket_name = f"{full_name_base}{get_random_string()}"
        print(f"⌛ Creating S3 {bucket_name}...")
        s3.create_bucket(Bucket=bucket_name)
        s3.put_bucket_encryption(Bucket=bucket_name, ServerSideEncryptionConfiguration={'Rules': [{'ApplyServerSideEncryptionByDefault': {'SSEAlgorithm': 'AES256'}}]})
        s3.put_public_access_block(Bucket=bucket_name, PublicAccessBlockConfiguration={'BlockPublicAcls': True, 'IgnorePublicAcls': True, 'BlockPublicPolicy': True, 'RestrictPublicBuckets': True})
        s3.put_bucket_versioning(Bucket=bucket_name, VersioningConfiguration={'Status': 'Enabled'})
    
    discovery_data['storage'][name] = bucket_name

if __name__ == "__main__":
    setup_environment("dev", "10.0.0.0/16", "10.0.1.0/24", "10.0.3.0/24", "10.0.2.0/24", "10.0.4.0/24")
    setup_environment("prod", "10.1.0.0/16", "10.1.1.0/24", "10.1.3.0/24", "10.1.2.0/24", "10.1.4.0/24")
    
    print("\n📦 --- Building Storage ---")
    setup_s3("capstone-dev")
    setup_s3("capstone-prod")
    setup_s3("capstone-tfstate")

    # Save to JSON
    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    
    print("\n" + "="*50)
    print("🔥 DISCOVERY COMPLETE! metadata saved to discovery.json")
    print("="*50)
    print(f"VPC DEV: {discovery_data['dev']['vpc_id']}")
    print(f"VPC PROD: {discovery_data['prod']['vpc_id']}")
    print(f"ALB DEV DNS: {discovery_data['dev']['alb']['dns']}")
    print(f"NLB DEV DNS: {discovery_data['dev']['nlb']['dns']}")
    print("="*50)
