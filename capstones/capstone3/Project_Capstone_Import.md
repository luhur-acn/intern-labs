# Capstone Project: The Great Migration

| Difficulty | Est. Time | Prerequisites |
|------------|-----------|---------------|
| Advanced | 3–4 Hours | Labs 1–13 |

## 🎯 Vision

You are a Cloud Engineer tasked with modernizing a legacy environment. A previous team built a multi-environment setup **manually through the AWS Console — with no documentation**. Your mission is to:

1. **Discover** what was built by querying the live AWS account using the CLI and SDK.
2. **Validate** the discovered data by cross-referencing multiple AWS APIs.
3. **Codify** the infrastructure into a production-grade Terragrunt repository using `import` blocks.
4. **Prove control** by making infrastructure changes exclusively through code.

> **Pluralsight Sandbox Note**: All AWS resource types used in this project are supported within the Pluralsight sandbox environment. The sandbox provides a temporary AWS account with permissions for EC2, VPC, S3, ELB, and IAM. Ensure you note your sandbox session expiry before starting.

---

## 🗺️ Project Architecture

The project requires **two distinct environments** (Dev and Prod) within the same AWS account, each with its own isolated network stack and a shared S3 state bucket.

```mermaid
graph TB
    %% Styling (AWS Standards)
    classDef vpc fill:none,stroke:#8c4fff,stroke-width:2px;
    classDef subnet fill:none,stroke:#8c4fff,stroke-width:2px,stroke-dasharray: 5 5;
    classDef compute fill:none,stroke:#ff9900,stroke-width:1px;
    classDef s3 fill:none,stroke:#3b48cc,stroke-width:2px;
    classDef env fill:none,stroke:#545b64,stroke-width:2px,stroke-dasharray: 10 5;
    classDef external fill:none,stroke:#545b64,stroke-width:1px;

    subgraph AWS_Acc ["AWS Account"]
        direction TB

        TFState[(S3: tf-state-backend)]

        subgraph DevEnv ["DEV ENVIRONMENT"]
            direction TB
            D_S3[(S3: capstone-dev)]
            subgraph DevVPC ["VPC: 10.0.0.0/16"]
                direction LR
                subgraph DevPub ["Public Subnet A (10.0.1.0/24)"]
                    D_EIP[Elastic IP] --> D_NLB(NLB)
                    D_NLB --> D_ALB(ALB)
                end
                subgraph DevPubB ["Public Subnet B (10.0.3.0/24)"]
                end
                subgraph DevPriv ["Private Subnet A (10.0.2.0/24)"]
                    D_ALB --> D_EC2[EC2: web-dev]
                end
                subgraph DevPrivB ["Private Subnet B (10.0.4.0/24)"]
                end
            end
        end

        subgraph ProdEnv ["PROD ENVIRONMENT"]
            direction TB
            P_S3[(S3: capstone-prod)]
            subgraph ProdVPC ["VPC: 10.1.0.0/16"]
                direction LR
                subgraph ProdPub ["Public Subnet A (10.1.1.0/24)"]
                    P_EIP[Elastic IP] --> P_NLB(NLB)
                    P_NLB --> P_ALB(ALB)
                end
                subgraph ProdPubB ["Public Subnet B (10.1.3.0/24)"]
                end
                subgraph ProdPriv ["Private Subnet A (10.1.2.0/24)"]
                    P_ALB --> P_EC2[EC2: web-prod]
                end
                subgraph ProdPrivB ["Private Subnet B (10.1.4.0/24)"]
                end
            end
        end
    end

    %% Invisible links to prevent layout engine overlap
    TFState ~~~ DevEnv
    DevEnv ~~~ ProdEnv

    %% Assign Classes
    class DevEnv,ProdEnv env;
    class DevVPC,ProdVPC vpc;
    class DevPub,DevPubB,DevPriv,DevPrivB,ProdPub,ProdPubB,ProdPriv,ProdPrivB subnet;
    class D_EC2,P_EC2 compute;
    class D_S3,P_S3,TFState s3;
    class D_EIP,D_NLB,D_ALB,P_EIP,P_NLB,P_ALB external;
    class AWS_Acc env;
```

---

## 📋 Technical Specifications

---

### Phase 1: The Manual Build (Console)

You must build the following components manually through the AWS Console. **No automation is allowed in this phase.** This simulates a legacy environment left behind by a previous team.

#### 🛠️ Tools Needed
- **AWS Management Console**
- **Web Browser**

#### 📦 Deliverables
- **Live Infrastructure**: A fully functional Dev and Prod environment as defined below.
- **Console Screenshots**: Capture the detail page of each resource (VPC, Subnets, EC2, ALB, NLB, S3) showing its ID/ARN and Name tag.

---

#### 1. Networking (Per Environment)

Each environment requires **two** public and **two** private subnets (to satisfy ALB's multi-AZ requirement).

| Resource | Dev | Prod |
| :--- | :--- | :--- |
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` |
| **Public Subnet A** | `10.0.1.0/24` (AZ-a) | `10.1.1.0/24` (AZ-a) |
| **Public Subnet B** | `10.0.3.0/24` (AZ-b) | `10.1.3.0/24` (AZ-b) |
| **Private Subnet A** | `10.0.2.0/24` (AZ-a) | `10.1.2.0/24` (AZ-a) |
| **Private Subnet B** | `10.0.4.0/24` (AZ-b) | `10.1.4.0/24` (AZ-b) |
| **Internet Gateway** | Attached to VPC | Attached to VPC |
| **NAT Gateway** | In Public Subnet A, with Elastic IP | In Public Subnet A, with Elastic IP |
| **Public Route Table** | Routes `0.0.0.0/0` → IGW; Associated to both Public Subnets | Same |
| **Private Route Table** | Routes `0.0.0.0/0` → NAT GW; Associated to both Private Subnets | Same |

**Required Tags** (apply to every resource):

| Key | Value |
| :--- | :--- |
| `Name` | Descriptive name, e.g. `dev-vpc`, `prod-public-subnet-a` |
| `Environment` | `dev` or `prod` |
| `Project` | `capstone` |

---

#### 2. Compute

- **EC2 Instance** (one per environment):
  - Type: `t3.micro`, AMI: Amazon Linux 2023 (latest)
  - Placement: **Private Subnet A**
  - Security Group: `capstone-[env]-ec2-sg`
    - Inbound: HTTP (80) from ALB Security Group only
    - Inbound: SSH (22) from `10.0.0.0/8` (internal only)
  - User Data: Install and start a basic web server:
    ```bash
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Capstone [ENV] Server - $(hostname -f)</h1>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    ```
  - Name Tag: `web-dev` / `web-prod`

---

#### 3. Load Balancing

- **ALB (Application Load Balancer)**:
  - Scheme: `internet-facing`
  - Subnets: **Both Public Subnets** of the same environment
  - Security Group: `capstone-[env]-alb-sg`, inbound HTTP (80) from `0.0.0.0/0`
  - Target Group: `capstone-[env]-ec2-tg`, HTTP, target: EC2 instance (port 80)
  - Listener: HTTP (80) → Forward to target group
  - Health Check Path: `/`

- **NLB (Network Load Balancer)**:
  - Scheme: `internet-facing`
  - Subnets: **Public Subnet A** with a new **Elastic IP** assigned
  - Target Group: `capstone-[env]-alb-tg`, type: `alb`, target: the ALB above
  - Listener: TCP (80) → Forward to ALB target group

---

#### 4. Storage

- **S3 Buckets** (create three total):
  - `capstone-dev-[yourname]-[random]`: Dev application bucket
  - `capstone-prod-[yourname]-[random]`: Prod application bucket
  - `capstone-tfstate-[yourname]-[random]`: Terraform state backend bucket
  - All buckets: Enable **AES-256 encryption**, **Block all public access**, **Enable Versioning**.

---

### Phase 2: Deep Discovery (CLI & SDK)

> **This is the core of the capstone.** Before you touch a single line of Terraform, you must understand your target environment completely. You will write scripts to query the live AWS account and cross-reference the data.

#### 🛠️ Tools Needed
- **AWS CLI** (v2)
- **Python 3** + **Boto3**
- **`jq`** (for JSON parsing in Bash)

#### 📦 Deliverables
- **`discovery.sh`**: A Bash script using AWS CLI to query and print resource IDs.
- **`audit.py`**: A Python/Boto3 script that builds the full `discovery.json` file.
- **`discovery.json`**: The structured output file, populated by `audit.py`.

---

#### 2.1 Querying VPCs

You must identify your VPCs by filtering on the `Project` tag, not by assuming IDs.

**CLI Task — Find VPCs by tag:**
```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=capstone" \
  --query "Vpcs[*].{ID:VpcId, CIDR:CidrBlock, Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
```

**CLI Task — Find the Internet Gateway attached to a specific VPC** (replace `vpc-xxxxxx`):
```bash
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=vpc-xxxxxx" \
  --query "InternetGateways[*].{IGW_ID:InternetGatewayId, State:Attachments[0].State}" \
  --output table
```

**CLI Task — List all Route Tables for a VPC and their associations:**
```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-xxxxxx" \
  --query "RouteTables[*].{RT_ID:RouteTableId, Associations:Associations[*].SubnetId, Routes:Routes[*].{Dest:DestinationCidrBlock, GW:GatewayId}}" \
  --output json
```

**Validation Task**: Cross-reference the output. For each route table, confirm:
1. The public route table has a route to an IGW (`igw-*`).
2. The private route table has a route to a NAT Gateway (`nat-*`).
Document any discrepancies found.

---

#### 2.2 Querying Subnets

**CLI Task — List subnets with their type (public/private) using tags:**
```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxxx" \
  --query "Subnets[*].{ID:SubnetId, CIDR:CidrBlock, AZ:AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value, AutoPublicIP:MapPublicIpOnLaunch}" \
  --output table
```

**Validation Task**: For each subnet, confirm the `MapPublicIpOnLaunch` value:
- Public subnets: should be `True`.
- Private subnets: should be `False`.
If any mismatch is found, correct it in the Console and document it.

---

#### 2.3 Querying EC2 Instances

**CLI Task — Find instances by tag and retrieve full network details:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=capstone" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].{ID:InstanceId, Type:InstanceType, State:State.Name, PrivateIP:PrivateIpAddress, SubnetID:SubnetId, SG:SecurityGroups[*].GroupId, Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
```

**CLI Task — Query the Security Group rules for a specific instance's SG** (replace `sg-xxxxxx`):
```bash
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxxxxx" \
  --query "SecurityGroupRules[*].{RuleID:SecurityGroupRuleId, Direction:IsEgress, Protocol:IpProtocol, FromPort:FromPort, ToPort:ToPort, CIDR:CidrIpv4, SG_Source:ReferencedGroupInfo.GroupId}" \
  --output table
```

**Validation Task**: Confirm that port 80 inbound on the EC2 security group references the **ALB security group ID**, not `0.0.0.0/0`. Document the source SG ID.

---

#### 2.4 Querying Load Balancers

**CLI Task — List all ALBs with their DNS name and state:**
```bash
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Type=='application'].{Name:LoadBalancerName, ARN:LoadBalancerArn, DNS:DNSName, State:State.Code, Scheme:Scheme}" \
  --output table
```

**CLI Task — Get the listeners for a specific ALB** (replace `arn:aws:elasticloadbalancing:...`):
```bash
aws elbv2 describe-listeners \
  --load-balancer-arn "arn:aws:elasticloadbalancing:..." \
  --query "Listeners[*].{ARN:ListenerArn, Port:Port, Protocol:Protocol, DefaultAction:DefaultActions[0].Type, TargetGroup:DefaultActions[0].TargetGroupArn}" \
  --output table
```

**CLI Task — List all NLBs:**
```bash
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?Type=='network'].{Name:LoadBalancerName, ARN:LoadBalancerArn, DNS:DNSName, State:State.Code}" \
  --output table
```

**CLI Task — Query Target Group health and target registration:**
```bash
# First, get all Target Group ARNs
aws elbv2 describe-target-groups \
  --query "TargetGroups[*].{Name:TargetGroupName, ARN:TargetGroupArn, Type:TargetType, Protocol:Protocol, Port:Port}" \
  --output table

# Then, for each TG ARN, check health:
aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:..." \
  --query "TargetHealthDescriptions[*].{Target:Target.Id, Port:Target.Port, Health:TargetHealth.State, Reason:TargetHealth.Reason}" \
  --output table
```

**Validation Task**: All EC2 targets in the ALB target group must be `healthy`. If any are `unhealthy`, SSH to the instance (via Session Manager) and verify `httpd` is running (`systemctl status httpd`). Do not proceed to Phase 3 until all targets are healthy.

---

#### 2.5 Querying Elastic IPs & NAT Gateways

**CLI Task — List all Elastic IPs with their associated resources:**
```bash
aws ec2 describe-addresses \
  --query "Addresses[*].{AllocationID:AllocationId, PublicIP:PublicIp, AssociationID:AssociationId, AssociatedInstanceID:InstanceId, NatGateway:NetworkInterfaceId}" \
  --output table
```

**CLI Task — List NAT Gateways and confirm their EIP and subnet placement:**
```bash
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=capstone" \
  --query "NatGateways[*].{ID:NatGatewayId, State:State, SubnetID:SubnetId, EIP:NatGatewayAddresses[0].PublicIp, AllocationID:NatGatewayAddresses[0].AllocationId}" \
  --output table
```

**Validation Task**: Cross-reference the NAT Gateway's `SubnetId` against your subnet list from §2.2. Confirm each NAT Gateway is in a **public** subnet.

---

#### 2.6 Querying S3 Buckets

**CLI Task — List all project buckets:**
```bash
aws s3api list-buckets \
  --query "Buckets[?contains(Name, 'capstone')].{Name:Name, Created:CreationDate}" \
  --output table
```

**CLI Task — Verify encryption for each bucket** (replace `<bucket-name>`):
```bash
aws s3api get-bucket-encryption \
  --bucket <bucket-name> \
  --query "ServerSideEncryptionConfiguration.Rules[*].ApplyServerSideEncryptionByDefault.{Algorithm:SSEAlgorithm}" \
  --output table
```

**CLI Task — Verify versioning status:**
```bash
aws s3api get-bucket-versioning --bucket <bucket-name>
```

**CLI Task — Verify Block Public Access settings:**
```bash
aws s3api get-public-access-block --bucket <bucket-name>
```

**Validation Task**: Complete the following table in your `discovery.json`. All values must be confirmed, not assumed.

| Bucket Name | Encryption | Versioning | Public Access Blocked |
| :--- | :--- | :--- | :--- |
| `capstone-dev-...` | ✓/✗ | ✓/✗ | ✓/✗ |
| `capstone-prod-...` | ✓/✗ | ✓/✗ | ✓/✗ |
| `capstone-tfstate-...` | ✓/✗ | ✓/✗ | ✓/✗ |

---

#### 2.7 The Audit Script (`audit.py`)

Write a **Python script** using Boto3 that collects all the above data and writes it to a structured `discovery.json`. The script must:

1. Use `boto3` paginators (not simple list calls) to handle large result sets.
2. Filter resources using tags (`Project=capstone`) rather than hardcoded IDs.
3. Resolve **cross-references**: For each EC2 instance, embed its subnet's Name tag and its security group's inbound rules.
4. Resolve **cross-references**: For each ALB listener, embed the target group's health status.
5. Output a structured JSON file with the following top-level keys:

```json
{
  "discovery_timestamp": "...",
  "region": "us-east-1",
  "dev": {
    "vpc": { "id": "vpc-...", "cidr": "10.0.0.0/16", "igw_id": "igw-...", "nat_gateway_id": "nat-..." },
    "subnets": [ { "id": "subnet-...", "cidr": "...", "type": "public|private", "az": "..." } ],
    "route_tables": [ { "id": "rtb-...", "type": "public|private", "routes": [...] } ],
    "ec2": { "id": "i-...", "private_ip": "...", "security_group_id": "sg-..." },
    "alb": { "arn": "...", "dns": "...", "listener_arn": "...", "target_group_arn": "...", "target_health": "healthy|unhealthy" },
    "nlb": { "arn": "...", "dns": "...", "eip_allocation_id": "...", "target_group_arn": "..." },
    "s3": { "name": "...", "arn": "...", "encrypted": true, "versioning": true }
  },
  "prod": { "...": "same structure as dev" },
  "tfstate_bucket": { "name": "...", "arn": "..." }
}
```

**Run your script and verify the output is valid JSON:**
```bash
python3 audit.py
jq . discovery.json
```

---

### Phase 3: The Migration (Terragrunt + Import Blocks)

Your goal is to bring all resources under Terragrunt management **without triggering any Replacement** (Destroy/Create). You must use **Terraform `import` blocks** (not the `terragrunt import` CLI command) for this phase.

#### 🛠️ Tools Needed
- **Terragrunt** (v0.50+)
- **Terraform** (v1.5+)
- **Git**

#### 📦 Deliverables
- **Complete `infrastructure/` Repository**: A DRY Terragrunt structure as specified below.
- **`import.tf` files**: One `import.tf` per resource module, containing the `import` blocks.
- **`plan --no-changes` Logs**: Output of `terragrunt run-all plan` showing **"No changes"** for every module.

---

#### 3.1 Repository Structure

```text
infrastructure/
├── root.hcl                  # Root: remote state, provider config
├── dev/
│   ├── env.hcl               # Dev-specific locals (env = "dev", CIDR = "10.0.0.0/16")
│   ├── vpc/
│   │   └── terragrunt.hcl
│   ├── subnets/
│   │   └── terragrunt.hcl
│   ├── security-groups/
│   │   └── terragrunt.hcl
│   ├── alb/
│   │   └── terragrunt.hcl
│   ├── nlb/
│   │   └── terragrunt.hcl
│   ├── ec2/
│   │   └── terragrunt.hcl
│   └── s3/
│       └── terragrunt.hcl
└── prod/
    ├── env.hcl               # Prod-specific locals (env = "prod", CIDR = "10.1.0.0/16")
    ├── vpc/
    │   └── terragrunt.hcl
    ├── subnets/
    │   └── terragrunt.hcl
    ├── security-groups/
    │   └── terragrunt.hcl
    ├── alb/
    │   └── terragrunt.hcl
    ├── nlb/
    │   └── terragrunt.hcl
    ├── ec2/
    │   └── terragrunt.hcl
    └── s3/
        └── terragrunt.hcl
```

---

#### 3.2 Module Specifications

> **Rule**: You may NOT use any modules from the Terraform Registry (e.g., `terraform-aws-modules`). Every module must be authored by you. Each module must use `for_each` to support a variable number of resources driven by input maps/lists.

---

##### 3.2.1 Module: VPC (`modules/vpc/`)

**Required files**: `main.tf`, `variables.tf`, `outputs.tf`

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| VPC | `aws_vpc` | `for_each` over `var.vpcs` map |
| Internet Gateway | `aws_internet_gateway` | `for_each` over `var.vpcs` |

**Required Variables** (`variables.tf`):

```hcl
variable "vpcs" {
  type = map(object({
    cidr_block = string
    enable_igw = optional(bool, true)
  }))
}
variable "environment"  { type = string }
variable "tags"         { type = map(string), default = {} }
```

**Required Outputs** (`outputs.tf`):

```hcl
output "vpc_ids" { value = { for k, v in aws_vpc.this : k => v.id } }
output "igw_ids" { value = { for k, v in aws_internet_gateway.this : k => v.id } }
```

---

##### 3.2.2 Module: Subnets (`modules/subnets/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| Subnets | `aws_subnet` | `for_each` over `var.subnets` map |
| NAT Gateway | `aws_nat_gateway` | 1 per module call |
| Elastic IP (for NAT) | `aws_eip` | 1 per module call |
| Public Route Table | `aws_route_table` | 1 per module call |
| Private Route Table | `aws_route_table` | 1 per module call |
| RT Associations | `aws_route_table_association` | `for_each` — 1 per subnet |

**Required Variables**:

```hcl
variable "vpc_id"       { type = string }
variable "igw_id"       { type = string }
variable "environment"  { type = string }
variable "tags"         { type = map(string), default = {} }

variable "subnets" {
  description = "Map of subnets to create. Each key becomes the subnet name suffix."
  type = map(object({
    cidr_block        = string
    availability_zone = string
    tier              = string   # "public" or "private"
  }))
}
```

> **Scalability**: Define as many subnets as needed. Adding a third AZ or a new subnet is a data change, not a code change. Use `each.value.tier` to conditionally set `map_public_ip_on_launch` and route table associations.

**Required Outputs**:

```hcl
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}
output "public_subnet_ids" {
  value = [for k, s in aws_subnet.this : s.id if var.subnets[k].tier == "public"]
}
output "private_subnet_ids" {
  value = [for k, s in aws_subnet.this : s.id if var.subnets[k].tier == "private"]
}
output "nat_gateway_id"    { value = aws_nat_gateway.this.id }
output "public_rt_id"      { value = aws_route_table.public.id }
output "private_rt_id"     { value = aws_route_table.private.id }
```

---

##### 3.2.3 Module: Security Groups (`modules/security-groups/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| Security Groups | `aws_security_group` | `for_each` over `var.security_groups` map keys |
| Ingress Rules | `aws_vpc_security_group_ingress_rule` | `for_each` — flattened from each SG's `ingress_rules` |
| Egress Rules | `aws_vpc_security_group_egress_rule` | `for_each` — 1 allow-all per SG |

**Design requirement**: Do not use inline `ingress` / `egress` blocks inside `aws_security_group`. Use separate rule resources to avoid Terraform conflicts.

**Required Variables**:

```hcl
variable "vpc_id"       { type = string }
variable "environment"  { type = string }
variable "tags"         { type = map(string), default = {} }

variable "security_groups" {
  description = "Map of security groups to create, each with dynamic ingress rules."
  type = map(object({
    description   = string
    ingress_rules = list(object({
      description              = string
      from_port                = number
      to_port                  = number
      ip_protocol              = string
      cidr_ipv4                = optional(string)
      referenced_security_group_id = optional(string)
    }))
  }))
}
```

> **Scalability**: Define as many SGs as needed (e.g., `ec2`, `alb`), each with an arbitrary number of ingress rules. The `referenced_security_group_id` field allows SG-to-SG references (e.g., ALB → EC2). You will need to flatten the nested rules into a single `for_each`-compatible map using `locals`.

**Required Outputs**:

```hcl
output "security_group_ids" {
  value = { for k, sg in aws_security_group.this : k => sg.id }
}
```

---

##### 3.2.4 Module: EC2 (`modules/ec2/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| EC2 Instances | `aws_instance` | `for_each` over `var.instances` map |
| IAM Role | `aws_iam_role` | 1 shared role per module call |
| IAM Instance Profile | `aws_iam_instance_profile` | 1 shared profile per module call |
| IAM Policy Attachment (SSM) | `aws_iam_role_policy_attachment` | 1 per module call |

**Required Variables**:

```hcl
variable "environment" { type = string }
variable "tags"        { type = map(string), default = {} }

variable "instances" {
  description = "Map of instances to create."
  type = map(object({
    ami_id             = string
    instance_type      = string
    subnet_id          = string
    security_group_ids = list(string)
    user_data          = optional(string, "")
  }))
}
```

**Required Outputs**:

```hcl
output "instance_ids" {
  value = { for k, inst in aws_instance.this : k => inst.id }
}
output "private_ips" {
  value = { for k, inst in aws_instance.this : k => inst.private_ip }
}
output "iam_role_arn" { value = aws_iam_role.this.arn }
```

---

##### 3.2.5 Module: ALB (`modules/alb/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| Application Load Balancer | `aws_lb` | `for_each` over `var.albs` map |
| Target Groups | `aws_lb_target_group` | `for_each` over `var.target_groups` map |
| Target Group Attachments | `aws_lb_target_group_attachment` | `for_each` over `var.target_group_attachments` map |
| Listeners | `aws_lb_listener` | `for_each` over `var.listeners` map |

**Required Variables**:

```hcl
variable "environment"        { type = string }
variable "vpc_id"             { type = string }
variable "tags"               { type = map(string), default = {} }

variable "albs" {
  type = map(object({
    internal           = optional(bool, false)
    security_group_ids = list(string)
    subnet_ids         = list(string)
  }))
}

variable "target_groups" {
  type = map(object({
    alb_key           = string
    port              = number
    protocol          = string
    target_type       = string
    health_check_path = optional(string, "/")
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    alb_key          = string
    port             = number
    protocol         = string
    target_group_key = string
  }))
}
```

> **Scalability**: Add more ALBs, target groups, listeners, or attachments by adding keys to the respective maps. Each TG and Listener must specify an `alb_key` to associate with the correct load balancer.

**Required Outputs**:

```hcl
output "alb_arns" { value = { for k, v in aws_lb.this : k => v.arn } }
output "alb_dns_names" { value = { for k, v in aws_lb.this : k => v.dns_name } }
output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
output "listener_arns" {
  value = { for k, l in aws_lb_listener.this : k => l.arn }
}
```

---

##### 3.2.6 Module: NLB (`modules/nlb/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| Network Load Balancer | `aws_lb` | `for_each` over `var.nlbs` map |
| Target Groups | `aws_lb_target_group` | `for_each` over `var.target_groups` map |
| Target Group Attachments | `aws_lb_target_group_attachment` | `for_each` over `var.target_group_attachments` map |
| Listeners | `aws_lb_listener` | `for_each` over `var.listeners` map |

**Required Variables**:

```hcl
variable "environment"  { type = string }
variable "vpc_id"       { type = string }
variable "tags"         { type = map(string), default = {} }

variable "nlbs" {
  type = map(object({
    internal           = optional(bool, false)
    subnet_mappings    = map(object({
      subnet_id     = string
      allocation_id = string
    }))
  }))
}

variable "target_groups" {
  type = map(object({
    nlb_key     = string
    port        = number
    protocol    = string
    target_type = string
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    nlb_key          = string
    port             = number
    protocol         = string
    target_group_key = string
  }))
}
```

**Required Outputs**:

```hcl
output "nlb_arns" { value = { for k, v in aws_lb.this : k => v.arn } }
output "nlb_dns_names" { value = { for k, v in aws_lb.this : k => v.dns_name } }
output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
```

---

##### 3.2.7 Module: S3 (`modules/s3/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| S3 Buckets | `aws_s3_bucket` | `for_each` over `var.buckets` map |
| Block Public Access | `aws_s3_bucket_public_access_block` | `for_each` — 1 per bucket |
| Encryption Config | `aws_s3_bucket_server_side_encryption_configuration` | `for_each` — 1 per bucket |
| Versioning Config | `aws_s3_bucket_versioning` | `for_each` — 1 per bucket |

**Required Variables**:

```hcl
variable "environment" { type = string }
variable "tags"        { type = map(string), default = {} }

variable "buckets" {
  description = "Map of S3 buckets to import/manage. Key = the exact existing bucket name."
  type = map(object({
    versioning_enabled = optional(bool, true)
  }))
}
```

> **Note for import**: Unlike Capstone 2, bucket names already exist. Use the exact bucket name as the map key so imports align correctly.

**Required Outputs**:

```hcl
output "bucket_names" {
  value = { for k, b in aws_s3_bucket.this : k => b.id }
}
output "bucket_arns" {
  value = { for k, b in aws_s3_bucket.this : k => b.arn }
}
```

---

#### 3.3 Terragrunt Wiring

##### `env.hcl`

This file contains only **shared, environment-level** variables. Resource-specific inputs live in each stack's `terragrunt.hcl`.

```hcl
# dev/env.hcl
locals {
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  ami_id      = "ami-0c02fb55956c7d316"  # Amazon Linux 2023 us-east-1
}
```

---

##### Example: `dev/vpc/terragrunt.hcl` (simple — no dependencies)

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//vpc"
}

inputs = {
  vpc_cidr    = local.env.vpc_cidr
  environment = local.env.environment
}
```

---

##### Example: `dev/ec2/terragrunt.hcl` (with dependencies and inline inputs)

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//ec2"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    private_subnet_ids = ["subnet-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { ec2 = "sg-00000000000000000" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = local.env.environment

  instances = {
    web = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.micro"
      subnet_id          = dependency.subnets.outputs.private_subnet_ids[0]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      user_data          = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        echo "<h1>Capstone Dev Server - $(hostname -f)</h1>" > /var/www/html/index.html
        systemctl start httpd && systemctl enable httpd
      EOF
    }
  }
}
```

---

##### Task: Wire the remaining stacks

Using the two examples above as a pattern, create `terragrunt.hcl` files for: **subnets**, **security-groups**, **alb**, **nlb**, and **s3**. Each must:

- Include `root.hcl` and read `env.hcl`
- Declare `dependency` blocks for upstream stacks (refer to the dependency graph in §3.5)
- Define `mock_outputs` matching the upstream module's output shapes
- Define resource-specific inputs **inline** (not in `env.hcl`)

Replicate the same structure under `prod/` with `prod/env.hcl` using CIDR `10.1.0.0/16`.

---

#### 3.4 The `import` Block Pattern

Each `terragrunt.hcl` must have a sibling `import.tf` file. Use the IDs from `discovery.json` to populate them. Resource addresses must match the `for_each` keys defined in the modules.

**Example `dev/vpc/import.tf`:**
```hcl
import {
  to = module.vpc.aws_vpc.this["main"]
  id = "vpc-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.vpc.aws_internet_gateway.this["main"]
  id = "igw-xxxxxxxxxxxxxxxxx"
}
```

**Example `dev/subnets/import.tf`** — keys must match the `subnets` map:
```hcl
import {
  to = module.subnets.aws_subnet.this["public-a"]
  id = "subnet-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_subnet.this["private-a"]
  id = "subnet-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_subnet.this["public-b"]
  id = "subnet-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_subnet.this["private-b"]
  id = "subnet-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_nat_gateway.this
  id = "nat-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_eip.this
  id = "eipalloc-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_route_table.public
  id = "rtb-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.subnets.aws_route_table.private
  id = "rtb-xxxxxxxxxxxxxxxxx"
}
```

**Example `dev/security-groups/import.tf`** — keys must match the `security_groups` map:
```hcl
import {
  to = module.security_groups.aws_security_group.this["ec2"]
  id = "sg-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.security_groups.aws_security_group.this["alb"]
  id = "sg-xxxxxxxxxxxxxxxxx"
}

# Import each ingress rule by its flattened key
import {
  to = module.security_groups.aws_vpc_security_group_ingress_rule.this["ec2-0"]
  id = "sgr-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.security_groups.aws_vpc_security_group_ingress_rule.this["ec2-1"]
  id = "sgr-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.security_groups.aws_vpc_security_group_ingress_rule.this["alb-0"]
  id = "sgr-xxxxxxxxxxxxxxxxx"
}
```

**Example `dev/ec2/import.tf`** — keys must match the `instances` map:
```hcl
import {
  to = module.ec2.aws_instance.this["web"]
  id = "i-xxxxxxxxxxxxxxxxx"
}

import {
  to = module.ec2.aws_iam_role.this
  id = "capstone-dev-ec2-role"
}

import {
  to = module.ec2.aws_iam_instance_profile.this
  id = "capstone-dev-ec2-profile"
}
```

---

#### 3.5 Import Order (Dependency-Aware)

Resources have dependencies. You must import them **in this order** to avoid state errors:

```mermaid
graph LR
    VPC --> Subnets
    Subnets --> SG[Security Groups]
    SG --> EC2
    Subnets --> ALB
    SG --> ALB
    EC2 --> ALB
    ALB --> NLB
    S3
```

Import and verify each layer before proceeding to the next. Check with `terragrunt plan` after each module import.

---

#### 3.6 The Root Configuration (`root.hcl`)

Your root config must configure the remote state backend using the `capstone-tfstate-*` bucket you created.

```hcl
# root.hcl
locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  region      = "us-east-1"
  project     = "capstone"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "capstone-tfstate-[yourname]-[random]"
    key            = "${local.project}/${local.environment}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "capstone-tfstate-lock"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Project     = "${local.project}"
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
    }
  }
}
EOF
}
```

> **Note**: You must also create the DynamoDB table `capstone-tfstate-lock` manually in the Console before running Terragrunt. This table is used for state locking.

---

#### 3.7 Task: Wire `prod/` Independently

Replicate the same wiring for `prod/`. The `prod/env.hcl`:

```hcl
locals {
  environment = "prod"
  vpc_cidr    = "10.1.0.0/16"
  ami_id      = "ami-0c02fb55956c7d316"
}
```

Each stack's `terragrunt.hcl` under `prod/` follows the same pattern as `dev/` but with prod-specific values (e.g., `10.1.x.0/24` CIDRs, prod bucket names, prod resource IDs in `import.tf`).

> **Validation**: Run `terragrunt run-all validate` from within `infrastructure/dev/` only. Confirm it does not trigger any `prod` runs.

---

#### 3.8 Success Criteria

A successful migration is achieved when **all** of the following are true:

1. `terragrunt run-all plan` returns **"No changes. Your infrastructure matches the configuration."** for **every single module**.
2. State is stored in the S3 backend. Verify by running:
   ```bash
   aws s3 ls s3://capstone-tfstate-[yourname]-[random]/capstone/ --recursive
   ```
3. Each resource is addressed logically with `for_each` keys (e.g., `module.subnets.aws_subnet.this["public-a"]`). Verify by running:
   ```bash
   # From within a module folder:
   terragrunt state list
   ```

---

### Phase 4: Verification & Cross-Validation

Before claiming success, you must verify the **live infrastructure** against your **Terraform state** using the CLI. This prevents "lazy" imports that match the state file but don't reflect reality.

#### 4.1 State vs. Reality Check

For each resource type below, run the CLI command and compare the output against what `terragrunt state show` outputs.

**VPC:**
```bash
# Get CIDR from state
terragrunt state show 'module.vpc.aws_vpc.this["main"]' | grep cidr_block

# Compare against live reality
aws ec2 describe-vpcs --vpc-ids vpc-xxxxxx --query "Vpcs[0].CidrBlock"
```

**Subnet (for_each-keyed):**
```bash
# Get CIDR from state (note the for_each key)
terragrunt state show 'module.subnets.aws_subnet.this["public-a"]' | grep cidr_block

# Compare against live reality
aws ec2 describe-subnets --subnet-ids subnet-xxxxxx --query "Subnets[0].CidrBlock"
```

**EC2 Instance (for_each-keyed):**
```bash
# Get private IP from state
terragrunt state show 'module.ec2.aws_instance.this["web"]' | grep private_ip

# Compare against live reality
aws ec2 describe-instances --instance-ids i-xxxxxx \
  --query "Reservations[0].Instances[0].PrivateIpAddress"
```

**S3 Bucket Versioning (for_each-keyed):**
```bash
# Get versioning from state
terragrunt state show 'module.s3.aws_s3_bucket_versioning.this["capstone-dev-yourname-random"]' | grep status

# Compare against live reality
aws s3api get-bucket-versioning --bucket capstone-dev-[yourname]-[random]
```

**Task**: Run all comparisons for **both** environments and document the results in a `verification_report.md` file. All values must match.

---

#### 4.2 End-to-End Connectivity Test

Query the NLB's public DNS name and verify the web server responds:

```bash
# Get NLB DNS from CLI (do not use Console)
NLB_DNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, 'capstone-dev')].DNSName" \
  --output text)

echo "NLB DNS: $NLB_DNS"

# Test HTTP response (may take 1-2 minutes for NLB to register ALB target)
curl -I http://$NLB_DNS
```

Expected response: `HTTP/1.1 200 OK` with the `web-dev` server hostname in the body.

Repeat for `capstone-prod`.

---

### Phase 5: Lifecycle Management & Hardening

To prove you are in full control, perform **all** of the following modifications exclusively via Terraform code changes. No Console changes are allowed.

#### 🛠️ Tools Needed
- **Terragrunt**
- **AWS CLI** (for verification only)

#### 📦 Deliverables
- **Clean `apply` Logs**: Showing only the expected changes (no replacements).
- **CLI Verification Output**: For each change below, a CLI command confirming the change was applied.

---

#### 5.1 Tagging Enforcement

Add two new tags to **all resources** via the `root.hcl` provider's `default_tags` block:

| Tag Key | Tag Value |
| :--- | :--- |
| `MigrationDate` | Today's date (`YYYY-MM-DD`) |
| `Owner` | Your name |

**Verify with CLI** after apply (check one EC2 instance as representative):
```bash
aws ec2 describe-instances \
  --instance-ids i-xxxxxx \
  --query "Reservations[0].Instances[0].Tags[?Key=='MigrationDate' || Key=='Owner']" \
  --output table
```

---

#### 5.2 Security Group Hardening

Update the `security_groups` map in your `security-groups/terragrunt.hcl`:

1. **Remove** the `cidr_ipv4 = "10.0.0.0/8"` SSH rule from the `ec2` SG.
2. **Add** a new rule: allow SSH (22) **only from your current public IP**.

First, query your current public IP from the CLI:
```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)/32
echo "Your IP: $MY_IP"
```

Update the `ec2` security group's `ingress_rules` list in `security-groups/terragrunt.hcl`:
```hcl
    ec2 = {
      description = "EC2 instance traffic"
      ingress_rules = [
        { description = "HTTP from ALB", from_port = 80, to_port = 80, ip_protocol = "tcp", referenced_security_group_id = "sg-alb-id" },
        { description = "SSH from my IP", from_port = 22, to_port = 22, ip_protocol = "tcp", cidr_ipv4 = "YOUR_IP/32" },
      ]
    }
```

**Verify with CLI** after apply:
```bash
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxxxxx" \
  --query "SecurityGroupRules[?!IsEgress && FromPort==\`22\`]" \
  --output table
```

Confirm: Only **one** SSH rule exists, and it references **your IP**.

---

#### 5.3 ALB Access Logging

Enable access logging on **both** ALBs by adding `access_logs` to `alb/terragrunt.hcl` inputs:

```hcl
inputs = {
  # ... existing inputs
  access_logs = {
    bucket  = "capstone-[env]-[yourname]-[random]"
    prefix  = "alb-access-logs"
    enabled = true
  }
}
```

> **Note**: You must add an S3 bucket policy allowing the AWS ELB service account to write logs. Look up the ELB account ID for your region and add it as a bucket policy in your `s3/terragrunt.hcl`.

**Verify with CLI** after apply:
```bash
aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn "arn:aws:elasticloadbalancing:..." \
  --query "Attributes[?Key=='access_logs.s3.enabled']"
```

---

#### 5.4 S3 Lifecycle Policy

Add a **lifecycle rule** to **both** application S3 buckets by updating `s3/terragrunt.hcl` inputs. Add `noncurrent_expiry_days` to each bucket in the `buckets` map:

```hcl
inputs = {
  environment = local.env.environment
  buckets = {
    "capstone-dev-[yourname]-[random]" = {
      versioning_enabled     = true
      noncurrent_expiry_days = 30
    }
  }
}
```

> This requires adding `noncurrent_expiry_days` as an optional field to the `buckets` variable and adding an `aws_s3_bucket_lifecycle_configuration` resource with `for_each` in your S3 module.

**Verify with CLI:**
```bash
aws s3api get-bucket-lifecycle-configuration --bucket capstone-dev-[yourname]-[random] \
  --query "Rules[*].{ID:ID, Status:Status, Expiration:NoncurrentVersionExpiration}"
```

---

## 🧹 Cleanup

Once the project is **fully verified**, destroy all Terragrunt-managed resources:

```bash
# From the infrastructure/ directory
terragrunt run-all destroy
```

Then manually delete resources **not managed by Terragrunt**:
1. The DynamoDB lock table (`capstone-tfstate-lock`) — delete from Console or CLI:
   ```bash
   aws dynamodb delete-table --table-name capstone-tfstate-lock
   ```
2. The state S3 bucket (must be emptied first before deletion):
   ```bash
   aws s3 rm s3://capstone-tfstate-[yourname]-[random] --recursive
   aws s3 rb s3://capstone-tfstate-[yourname]-[random]
   ```

> **Pluralsight Note**: The sandbox will automatically clean up any remaining resources at session expiry. However, proper cleanup is part of the assessment deliverables.

---

## ✅ Final Deliverable Checklist

| # | Deliverable | Description |
| :--: | :--- | :--- |
| 1 | Console Screenshots | Detail page of every manually created resource |
| 2 | `discovery.sh` | CLI-based discovery script |
| 3 | `audit.py` | Boto3 audit script with paginators and cross-references |
| 4 | `discovery.json` | Full structured resource map output by `audit.py` |
| 5 | `modules/` | Scalable Terraform modules with `for_each` (VPC, Subnets, SGs, EC2, ALB, NLB, S3) |
| 6 | `infrastructure/` (Git repo) | Complete DRY Terragrunt repo with `import.tf` files and per-stack inputs |
| 7 | Plan "No Changes" Log | `terragrunt run-all plan` log before Phase 5 changes |
| 8 | `verification_report.md` | State vs. reality comparison for all `for_each`-keyed resources |
| 9 | Phase 5 Apply Log | Clean `terragrunt run-all apply` showing only tag/SG/S3 changes |
| 10 | CLI Verification Output | CLI output confirming each Phase 5 change |
| 11 | `curl` HTTP Test | 200 OK response from both NLB DNS endpoints |
