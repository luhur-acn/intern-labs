# Cost Estimation (cost_estimate.md)

This cost estimate is based on the **us-east-1** region for a monthly period (approx. 730 hours), running 24/7.

| Component             | Configuration                         | Est. Monthly Cost |
| :-------------------- | :------------------------------------ | :---------------- |
| **EC2 (On-Demand)**   | 2 x t4g.nano (Compute + 8GB EBS gp3)  | $7.41             |
| **VPC (NAT Gateway)** | 1 x Regional NAT Gateway (+10GB Data) | $33.30            |
| **ALB**               | 1 x ALB + LCU Estimates               | $22.27            |
| **S3 Standard**       | 10GB Storage + 10k GET Requests       | $0.24             |
| **CloudWatch**        | 2 x Alarms + 2 x Metrics              | $0.80             |
| **Total (Monthly)**   |                                       | **$64.02**        |

## Cost Analysis

**What is the single largest cost driver, and how would you reduce it in a production environment?**

The largest cost driver in this architecture is the **NAT Gateway** ($33.30/month). This cost stems from the hourly uptime charge for the gateway (a single gateway for cost optimization) and the data processing charges.

### Strategies to reduce this cost:

### 1. **VPC Gateway Endpoints**: For S3 traffic, we have implemented a **Gateway Endpoint** (which is free). This significantly reduces NAT Gateway costs by keeping S3 data transfers within the AWS internal network.

2.  **Shared NAT Gateway**: In development or non-critical production environments, use a single NAT Gateway across multiple Availability Zones to halve the hourly cost, though this introduces a single point of failure.
3.  **IPv6-only Subnets**: Transitioning to IPv6-only subnets using **Egress-Only Internet Gateways** (which are free) eliminates the need for NAT Gateways for outbound-only internet traffic.
4.  **Compute Optimization**: For the ASG, using **Savings Plans** or **Reserved Instances** could reduce EC2 costs by up to 72% for predictable workloads. For non-production or flexible production workloads, **Spot Instances** can offer even deeper discounts.

**Why use On-Demand instead of Spot or Reserved Instances?**

On-Demand pricing was chosen for this initial design to provide **maximum flexibility without long-term commitment (1-3 years)**. This is ideal for development, testing, and projects where the resources might be terminated after a short period. It also serves as a **conservative baseline** for the budget, ensuring that any future optimization (like switching to Savings Plans) will only drive the cost down.

**Why is 8 GB EBS Storage chosen?**

1.  **OS Requirements**: Amazon Linux 2023 requires a minimum of 8 GB for a stable root partition. This ensures the OS has enough space for system logs, temporary files, and package updates.
2.  **Stateless Architecture**: Since all large static assets (images, videos, documents) are stored in **Amazon S3**, the EC2 instance doesn't need much local storage. 8 GB is the standard "minimum-best" size for cloud-init and micro-service deployments.
3.  **Cost Efficiency**: On the **gp3** volume type ($0.08/GB-month), 8 GB only costs **$0.64 per instance**. Increasing it to 20 GB or 100 GB would add unnecessary costs for space we don't actually use.
