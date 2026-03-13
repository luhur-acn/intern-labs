# 2.4_load_balancers/audit.py
import boto3, json

elbv2 = boto3.client('elbv2', region_name='us-east-1')

def audit_load_balancers():
    print("🕵️  Auditing Load Balancers, Listeners, and Targets...")
    lbs = elbv2.describe_load_balancers()['LoadBalancers']
    
    discovery_data = []

    for lb in lbs:
        if 'capstone' in lb['LoadBalancerName']:
            lb_arn = lb['LoadBalancerArn']
            lb_name = lb['LoadBalancerName']
            
            # Audit Listeners
            listeners = elbv2.describe_listeners(LoadBalancerArn=lb_arn)['Listeners']
            listener_data = []
            
            for l in listeners:
                tg_arn = l['DefaultActions'][0].get('TargetGroupArn')
                targets_list = []
                health_status = "N/A"
                
                if tg_arn:
                    # Get targets and their health
                    health_descriptions = elbv2.describe_target_health(TargetGroupArn=tg_arn)['TargetHealthDescriptions']
                    
                    if health_descriptions:
                        health_status = all(h['TargetHealth']['State'] == 'healthy' for h in health_descriptions)
                        for h in health_descriptions:
                            targets_list.append({
                                "TargetId": h['Target']['Id'],
                                "Port": h['Target']['Port'],
                                "HealthState": h['TargetHealth']['State'],
                                "Reason": h['TargetHealth'].get('Reason', 'Healthy')
                            })
                    else:
                        health_status = "No Targets Registered"

                listener_data.append({
                    "ListenerArn": l['ListenerArn'],
                    "Port": l['Port'],
                    "Protocol": l['Protocol'],
                    "TargetGroupArn": tg_arn,
                    "Targets": targets_list,
                    "Healthy": health_status
                })

            discovery_data.append({
                "LoadBalancerName": lb_name,
                "DNSName": lb['DNSName'],
                "Type": lb['Type'],
                "Listeners": listener_data,
                "Validation": {
                    "AllTargetsHealthy": all(ld['Healthy'] is True for ld in listener_data if isinstance(ld['Healthy'], bool)),
                    "Discrepancy": None if all(ld['Healthy'] is True for ld in listener_data if isinstance(ld['Healthy'], bool)) else "Issues detected in targets or listeners!"
                }
            })

    with open('discovery.json', 'w') as f:
        json.dump(discovery_data, f, indent=4)
    print("✅ 2.4 discovery.json generated with deep Target details.")

if __name__ == "__main__":
    audit_load_balancers()
