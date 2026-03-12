import boto3

def get_egress_rules():
    ec2 = boto3.client('ec2', region_name='us-east-1')
    sg_ids = ['sg-04cb5fa763ad46ac0', 'sg-05b97f940e061194a', 'sg-08f0a21aebe3d6f22', 'sg-0f2383e8894ea5a90']
    
    response = ec2.describe_security_group_rules(Filters=[{'Name': 'group-id', 'Values': sg_ids}])
    
    for rule in response['SecurityGroupRules']:
        if rule['IsEgress']:
            print(f"GroupId: {rule['GroupId']}, RuleId: {rule['SecurityGroupRuleId']}")

if __name__ == '__main__':
    get_egress_rules()
