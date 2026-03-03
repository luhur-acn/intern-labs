# Architecture Design: Capstone Web Application

## 1. VPC & Networking

- **VPC CIDR**: `10.0.0.0/16` — Justification: This range provides a broad address space of 65,536 private IP addresses, which allows for future scalability and clear segmentation of public and private tiers across multiple Availability Zones without risk of IP exhaustion.
- **AZs Used**: `us-east-1a`, `us-east-1b` — Justification: Using two AZs ensures high availability. If one AZ experiences an outage (e.g., physical failure, power loss), the remaining AZ will continue to serve traffic, satisfying the "Survive the failure of a single Availability Zone" constraint.
- **Public Subnets**:
  - `10.0.1.0/24` in `us-east-1a` — Hosts the NAT Gateway and ALB node.
  - `10.0.2.0/24` in `us-east-1b` — Justification: A second public subnet is included to satisfy the AWS requirement for Application Load Balancers to span at least two Availability Zones, ensuring the entry point remains highly available.
- **Private Subnets**:
  - `10.0.3.0/24` in `us-east-1a`
  - `10.0.4.0/24` in `us-east-1b`
- **NAT Gateway Decision**: 1 NAT Gateway (Total 1) — Justification: To optimize costs, a single NAT Gateway is deployed in Public Subnet 1. Both private subnets will route outbound traffic through this gateway. This is ideal for scenarios where the primary need for internet access is for software updates and external dependencies, rather than high-availability outbound traffic.

## 2. Connectivity & Traffic Flow

- **External Outbound (Internet)**: Private Subnets -> NAT Gateway (Public Subnet 1) -> Internet Gateway.
- **AWS Service Access (S3)**: Private Subnets -> **VPC Gateway Endpoint (S3)**. This keeps traffic within the AWS internal network, bypassing the NAT Gateway and eliminating data processing charges for S3 data transfers.
- **Management Access (SSM)**: Private Subnets -> NAT Gateway -> AWS Systems Manager (Port 443). Allows secure remote shell access without opening Port 22 (SSH) or using a Bastion Host.
- **Internal Inbound**: Public ALB -> Target Group (EC2 Instances) via Port 80.

## 2. Compute & Scaling

- **Instance Type**: `t4g.nano` — Justification: The most cost-efficient option for a lightweight web server. Powered by AWS Graviton2 (ARM), it offers 0.5 GiB RAM which is sufficient for simple Apache/Nginx workloads while reducing costs by ~60% compared to t3.micro.
- **AMI**: `Amazon Linux 2023 AMI (ARM64)` — Justification: Required to match the t4g.nano ARM architecture. Modern, secure, and optimized for Graviton processors.
- **Desired / Min / Max Capacity**: `2 / 2 / 4` — Justification: Desired/Min is set to 2 to ensure at least one instance is always running in each of the two AZs, providing immediate high availability. A Max capacity of 4 allows the system to double its resources to handle traffic surges.
- **Scale-Out Policy**: CPU > `70%` for `2` minutes — Justification: Triggers additional capacity when the current fleet is under moderate load, ensuring performance remains stable before reaching saturation. Eval period of 2 mins prevents scaling on brief spikes.
- **Scale-In Policy**: CPU < `30%` for `2` minutes — Justification: Consolidates resources when traffic subsides to optimize costs.
- **Health Check Grace Period**: `300 seconds` — Justification: This timeframe ensures the EC2 instance can complete its OS boot process, run the user data script (which might include software installation and configuration), and start the application service before the ALB begins health checks.

## 3. Load Balancer

- **ALB Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (Public Subnets)
- **Health Check Path**: `/` (or a dedicated `/health` endpoint if implemented)
- **Health Check Interval**: `30 seconds`
- **Healthy Threshold**: `3`
- **Unhealthy Threshold**: `3`

## 4. Security Groups

### ALB Security Group

| Direction | Protocol | Port | Source                       |
| :-------- | :------- | :--- | :--------------------------- |
| Inbound   | TCP      | 80   | 0.0.0.0/0 (Public Internet)  |
| Outbound  | TCP      | 80   | [EC2 SG ID] (Forward to app) |

### EC2 Security Group

| Direction | Protocol | Port | Source                                 |
| :-------- | :------- | :--- | :------------------------------------- |
| Inbound   | TCP      | 80   | [ALB SG ID] (Restricted to LB traffic) |
| Outbound  | TCP      | 443  | 0.0.0.0/0 (For software updates/SSM)   |

### Network ACL (Subnet Level)

| Type     | Protocol | Port Range | Source/Destination | Action | Reason                           |
| :------- | :------- | :--------- | :----------------- | :----- | :------------------------------- |
| Inbound  | TCP      | 1024-65535 | 0.0.0.0/0          | ALLOW  | Allow return traffic (Ephemeral) |
| Inbound  | TCP      | 80/443     | 0.0.0.0/0          | ALLOW  | Allow web/secure traffic         |
| Outbound | ALL      | ALL        | 0.0.0.0/0          | ALLOW  | Allow all outbound traffic       |

_Justification: Standard stateless security to allow web traffic and ephemeral return ports for NAT and SSM connectivity._

## 5. S3 & Static Assets

- **Bucket Name**: `capstone-static-assets-lab-unique-id`
- **Access Method**: IAM role on EC2 instance profile — Justification: This avoids hardcoding credentials. The instances are granted temporary security credentials automatically via the metadata service to interact with the S3 bucket.
- **Bucket Policy**: Allows `s3:GetObject` only for the IAM Role associated with the EC2 Instance Profile. All public access to the bucket is blocked.

## 6. IAM Roles & Permissions

- **Instance Profile**: `CapstoneEC2InstanceProfile`
- **IAM Role**: `CapstoneEC2Role`
- **Attached Policies**:
  - `AmazonSSMManagedInstanceCore`: **Mandatory for SSM**. Allows the instance to communicate with the Systems Manager service for remote shell access and patching.
  - `S3ReadOnlyPolicy`: **Custom Policy**. Grants `s3:GetObject` access only to the project bucket for downloading web assets and scripts.
- **Justification**: Using IAM Roles (Instance Profiles) is the AWS best practice for security. It provides temporary, automatically rotated credentials, eliminating the risk of hardcoded Access Keys or Secret Keys within the application or source code.

## 7. Observability

- **Alarm 1 (CPU Scale-Out)**: Metric: `CPUUtilization`, Threshold: `> 70%`, Period: `60s`, Eval Periods: `2`
- **Alarm 2 (5xx Errors)**: Metric: `HTTPCode_ELB_5XX_Count`, Threshold: `> 5`, Period: `60s`, Eval Periods: `1`
