#!/bin/bash
# setup_legacy_infra.sh — Simulates the Phase 1 manual build for Capstone 3 (Migration)
# NLB (with EIP) -> ALB (Multi-AZ) -> EC2 (Private Subnet A)

# Configuration
YOUR_NAME="justo" 
REGION="us-east-1"
PROJECT="capstone"

echo "🚀 Starting Phase 1: Creating Legacy Infrastructure (Dev & Prod)..."

setup_environment() {
    local ENV=$1
    local VPC_CIDR=$2
    local PUB_A=$3
    local PUB_B=$4
    local PRIV_A=$5
    local PRIV_B=$6

    echo "--- Building $ENV Environment ($VPC_CIDR) ---"

    # 1. VPC & IGW
    echo "Creating VPC..."
    VPC_OUT=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'VPC.VpcId' --output text 2>&1)
    if [[ $VPC_OUT == vpc-* ]]; then
        VPC_ID=$VPC_OUT
        echo "✅ Created VPC: $VPC_ID"
    else
        echo "❌ Failed to create VPC ($VPC_CIDR). AWS Error: $VPC_OUT"
        exit 1
    fi

    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$ENV-vpc Key=Environment,Value=$ENV Key=Project,Value=$PROJECT
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value": true}'
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value": true}'

    IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$ENV-igw Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

    # 2. Subnets
    SUB_PUB_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUB_A --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text)
    SUB_PUB_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUB_B --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text)
    SUB_PRIV_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIV_A --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text)
    SUB_PRIV_B=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIV_B --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text)

    aws ec2 create-tags --resources $SUB_PUB_A $SUB_PUB_B $SUB_PRIV_A $SUB_PRIV_B --tags Key=Environment,Value=$ENV Key=Project,Value=$PROJECT
    aws ec2 create-tags --resources $SUB_PUB_A --tags Key=Name,Value=$ENV-public-subnet-a
    aws ec2 create-tags --resources $SUB_PUB_B --tags Key=Name,Value=$ENV-public-subnet-b
    aws ec2 create-tags --resources $SUB_PRIV_A --tags Key=Name,Value=$ENV-private-subnet-a
    aws ec2 create-tags --resources $SUB_PRIV_B --tags Key=Name,Value=$ENV-private-subnet-b

    # 3. NAT Gateway
    EIP_NAT=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
    NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $SUB_PUB_A --allocation-id $EIP_NAT --query 'NatGateway.NatGatewayId' --output text)
    aws ec2 create-tags --resources $NAT_GW_ID --tags Key=Name,Value=$ENV-nat-gw Key=Environment,Value=$ENV Key=Project,Value=$PROJECT
    
    echo "Waiting for NAT Gateway ($NAT_GW_ID) to be available..."
    aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

    # 4. Route Tables
    RT_PUB=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-route --route-table-id $RT_PUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
    aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $SUB_PUB_A
    aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $SUB_PUB_B
    aws ec2 create-tags --resources $RT_PUB --tags Key=Name,Value=$ENV-public-rt Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

    RT_PRIV=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-route --route-table-id $RT_PRIV --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
    aws ec2 associate-route-table --route-table-id $RT_PRIV --subnet-id $SUB_PRIV_A
    aws ec2 associate-route-table --route-table-id $RT_PRIV --subnet-id $SUB_PRIV_B
    aws ec2 create-tags --resources $RT_PRIV --tags Key=Name,Value=$ENV-private-rt Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

    # 5. Security Groups
    ALB_SG_ID=$(aws ec2 create-security-group --group-name capstone-$ENV-alb-sg --description "ALB Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
    aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 create-tags --resources $ALB_SG_ID --tags Key=Name,Value=capstone-$ENV-alb-sg Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

    EC2_SG_ID=$(aws ec2 create-security-group --group-name capstone-$ENV-ec2-sg --description "EC2 Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
    aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 80 --source-group $ALB_SG_ID
    aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr 10.0.0.0/8
    aws ec2 create-tags --resources $EC2_SG_ID --tags Key=Name,Value=capstone-$ENV-ec2-sg Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

    # 6. EC2 Instance
    USER_DATA=$(cat <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
echo "<h1>Capstone $ENV Server - \$(hostname -f)</h1>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
)
    echo "$USER_DATA" > user_data.sh
    EC2_ID=$(aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --count 1 --instance-type t3.micro --subnet-id $SUB_PRIV_A --security-group-ids $EC2_SG_ID --user-data file://user_data.sh --query 'Instances[0].InstanceId' --output text)
    aws ec2 create-tags --resources $EC2_ID --tags Key=Name,Value=web-$ENV Key=Environment,Value=$ENV Key=Project,Value=$PROJECT
    rm user_data.sh

    # 7. ALB
    ALB_ARN=$(aws elbv2 create-load-balancer --name capstone-$ENV-alb --subnets $SUB_PUB_A $SUB_PUB_B --security-groups $ALB_SG_ID --query 'LoadBalancers[0].LoadBalancerArn' --output text)
    ALB_TG_ARN=$(aws elbv2 create-target-group --name capstone-$ENV-ec2-tg --protocol HTTP --port 80 --vpc-id $VPC_ID --target-type instance --query 'TargetGroups[0].TargetGroupArn' --output text)
    aws elbv2 register-targets --target-group-arn $ALB_TG_ARN --targets Id=$EC2_ID
    aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$ALB_TG_ARN --query 'Listeners[0].ListenerArn' --output text

    # 8. NLB (with Static EIP)
    EIP_NLB=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
    NLB_ARN=$(aws elbv2 create-load-balancer --name capstone-$ENV-nlb --type network --subnet-mappings SubnetId=$SUB_PUB_A,AllocationId=$EIP_NLB --query 'LoadBalancers[0].LoadBalancerArn' --output text)
    NLB_TG_ARN=$(aws elbv2 create-target-group --name capstone-$ENV-alb-tg --protocol TCP --port 80 --vpc-id $VPC_ID --target-type alb --query 'TargetGroups[0].TargetGroupArn' --output text)
    aws elbv2 register-targets --target-group-arn $NLB_TG_ARN --targets Id=$ALB_ARN
    aws elbv2 create-listener --load-balancer-arn $NLB_ARN --protocol TCP --port 80 --default-actions Type=forward,TargetGroupArn=$NLB_TG_ARN --query 'Listeners[0].ListenerArn' --output text

    echo "--- $ENV Environment Build Complete ---"
}

# Run Builds
setup_environment "dev" "10.0.0.0/16" "10.0.1.0/24" "10.0.4.0/24" "10.0.2.0/24" "10.0.5.0/24"
setup_environment "prod" "10.1.0.0/16" "10.1.1.0/24" "10.1.4.0/24" "10.1.2.0/24" "10.1.5.0/24"

# 9. S3 Buckets
create_bucket() {
    local BNAME=$1
    local EXTRA_NAME=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
    local B_FULL_NAME="$BNAME-$YOUR_NAME-$EXTRA_NAME"
    
    aws s3api create-bucket --bucket $B_FULL_NAME --region $REGION
    aws s3api put-bucket-encryption --bucket $B_FULL_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    aws s3api put-public-access-block --bucket $B_FULL_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    aws s3api put-bucket-versioning --bucket $B_FULL_NAME --versioning-configuration Status=Enabled
    echo "Bucket Created: $B_FULL_NAME"
}

create_bucket "capstone-dev"
create_bucket "capstone-prod"
create_bucket "capstone-tfstate"

echo "✅ Phase 1: All legacy infrastructure created successfully!"
