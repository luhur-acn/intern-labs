# 2.3_ec2_instances/audit.py
import boto3, json

ec2 = boto3.client('ec2', region_name='us-east-1')

def audit_ec2_networking():
    print("🕵️  Auditing EC2 Network Interfaces and Security Groups...")
    res = ec2.describe_instances(Filters=[{'Name': 'tag:Project', 'Values': ['capstone']}])['Reservations']
    
    discovery_data = []

    for r in res:
        for i in r['Instances']:
            instance_id = i['InstanceId']
            name = next((t['Value'] for t in i.get('Tags', []) if t['Key'] == 'Name'), "unnamed")
            
            # Audit Security Groups
            sgs = i.get('SecurityGroups', [])
            sg_details = []
            valid_ingress = False
            alb_sg_source = None

            for sg in sgs:
                sg_id = sg['GroupId']
                # Fetch rules for this SG
                rules = ec2.describe_security_group_rules(Filters=[{'Name': 'group-id', 'Values': [sg_id]}])['SecurityGroupRules']
                
                for rule in rules:
                    # Check Inbound Port 80 (HTTP)
                    if not rule.get('IsEgress') and rule.get('FromPort') == 80:
                        source_sg = rule.get('ReferencedGroupInfo', {}).get('GroupId')
                        if source_sg:
                            valid_ingress = True
                            alb_sg_source = source_sg
            
            discovery_data.append({
                "InstanceId": instance_id,
                "Name": name,
                "PrivateIp": i.get('PrivateIpAddress'),
                "SecurityGroups": [sg['GroupId'] for sg in sgs],
                "Validation": {
                    "Port80_Referencing_SG": valid_ingress,
                    "Source_SG_ID": alb_sg_source,
                    "Discrepancy": None if valid_ingress else "Port 80 Inbound potentially unsafe (missing SG reference)"
                }
            })

    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    print("✅ 2.3 discovery.json generated with SG validation.")

if __name__ == "__main__":
    audit_ec2_networking()
