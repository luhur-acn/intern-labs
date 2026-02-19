## Table of Contents
1. [Module 0: Cloud Computing Fundamentals](#module-0-cloud-computing-fundamentals)
2. [Module 1: IAM & AWS CLI Basics](#module-1-aws-introduction--iam)
3. [Module 2: VPC & Networking Basics](#module-2-virtual-private-cloud-vpc)
4. [Module 3: EC2 & S3 Storage](#module-3-compute--storage)
5. [Module 4: Load Balancers & Scaling](#module-4-high-availability--scaling)
6. [Module 5: Secure Networking (NACLs/SGs)](#module-5-security--dns)
7. [Module 6: AWS SDK for Python (Boto3)](#module-6-aws-sdk-for-python-boto3)
8. [Module 7: Terraform Fundamentals](#module-7-terraform-fundamentals)
9. [Module 8: Terragrunt & Advanced DRY](#module-8-terragrunt--advanced-dry)

---

## Module 0: Cloud Computing Fundamentals
*Understanding the 'Why' behind Cloud Computing.*

- **Concepts**: What is Cloud Computing? Benefits of Cloud (Agility, Cost, Elasticity).
- **Resources**:
    - [Roadmap.sh AWS](https://roadmap.sh/aws)
    - [Cloud Computing Explained: The Most Important Concepts To Know](https://www.youtube.com/watch?v=ZaA0kNm18pE)
    - [AWS Educate](https://aws.amazon.com/education/awseducate/)

---

## Module 1: AWS Introduction & IAM
*Your first steps into the AWS ecosystem.*

- **Objectives**: Setup AWS CLI, understand Regions/AZs, and manage permissions.
- **Resources**:
    - [What is AWS? Explained in Plain English (Video)](https://www.youtube.com/watch?v=W6jQmVi31Xk)
    - [Getting Started with AWS Cloud Essentials (AWS Skill Builder)](https://skillbuilder.aws/learn/Y738EQQD49/getting-started-with-aws-cloud-essentials/YEWD5RAWZJ)
    - [AWS Cloud Practitioner Essentials](https://skillbuilder.aws/learn/94T2BEN85A/aws-cloud-practitioner-essentials/8D79F3AVR7)
    - [AWS Cloud Quest: Cloud Practitioner](https://skillbuilder.aws/learn/FU5WCYVGKY/aws-cloud-quest-cloud-practitioner/JF9TKU68GT)
    - [Learning AWS from Scratch in 2025 (Video)](https://www.youtube.com/watch?v=0WVXTRMKXtE)
- **Related Lab**: [Lab 1: IAM & AWS CLI Basics](labs/01-IAM_CLI.md)

---

## Module 2: Virtual Private Cloud (VPC)
*Designing your own private network in the cloud.*

- **Objectives**: Understand subnets, route tables, IGWs, and NAT Gateways.
- **Resources**:
    - [Amazon VPC Basics Tutorial (Video)](https://www.youtube.com/watch?v=7_NNlnH7sAg)
    - [AWS Networking Basics](https://skillbuilder.aws/learn/S1VYRYHD8V/aws-networking-basics/SKP7248UVF?parentId=ZDTDSRZ9NE)
    - [AWS Networking Basics For Programmers (Video)](https://www.youtube.com/watch?v=2doSoMN2xvI)
    - [Subnets, Gateways, and Route Tables Explained](https://skillbuilder.aws/learn/D3C12EX9SU/subnets-gateways-and-route-tables-explained/FACFF89ATD?parentId=ZDTDSRZ9NE)
    - [Configuring and Deploying VPCs with Multiple Subnets](https://skillbuilder.aws/learn/4HWA8PME5S/configuring-and-deploying-vpcs-with-multiple-subnets/BTRCDVX2RU?parentId=ZDTDSRZ9NE)
    - [Introduction to Amazon Virtual Private Cloud (VPC)](https://skillbuilder.aws/learn/PH6Z6EVH8Z/introduction-to-amazon-virtual-private-cloud-vpc/PA8H7FUE15?parentId=ZDTDSRZ9NE)
    - [AWS Network Connectivity Options](https://skillbuilder.aws/learn/WQJNBEZYDW/aws-network-connectivity-options/PZDF9Z7DN5?parentId=ZDTDSRZ9NE)
    - [AWS VPC Beginner to Pro (FreeCodeCamp)](https://www.youtube.com/watch?v=g2JOHLHh4rI)
    - [How IP Addressing Works in AWS (Video)](https://www.youtube.com/watch?v=kRDtwr1dPpw)
    - [Internet Gateway VS NAT Gateway (Article)](https://aws.plainenglish.io/internet-gateway-vs-nat-gateway-a82c79958027)
    - [Keep Your Network Traffic in AWS with VPC Endpoints](https://www.youtube.com/watch?v=jo3X_aay4Vs)
- **Related Lab**: [Lab 2: VPC & Networking Basics](labs/02-VPC_Networking.md)

---

## Module 3: Compute & Storage
*Launching servers and managing data.*

- **Objectives**: Deploy EC2 instances and use S3 for object storage.
- **Resources**:
    - [Amazon EC2 Basics Tutorial (Video)](https://www.youtube.com/watch?v=hAk-7ImN6iM)
    - [Amazon S3 Basics Tutorial (Video)](https://www.youtube.com/watch?v=mDRoyPFJvlU)
    - [Create an Amazon EBS volume](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-creating-volume.html)
    - [Attach an Amazon EBS volume to an Amazon EC2 instance](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-attaching-volume.html)
    - [Make an Amazon EBS volume available for use](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-using-volumes.html)
- **Related Lab**: [Lab 3: EC2 & S3 Storage](labs/03-EC2_S3.md)

---

## Module 4: High Availability & Scaling
*Building systems that can handle traffic and recover from failure.*

- **Objectives**: Configure Load Balancers (ALB) and Auto Scaling Groups (ASG).
- **Resources**:
    - [Create an Application Load Balancer (Video)](https://www.youtube.com/watch?v=ZGGpEwThhrM)
    - [Route Traffic using Load Balancer Listener Rules (Video)](https://www.youtube.com/watch?v=0XMsnAgHXoo)
- **Related Lab**: [Lab 4: Load Balancers & Scaling](labs/04-ALB_ASG_Manual.md)

---

## Module 5: Security & DNS
*Securing your infrastructure and managing domain names.*

- **Objectives**: Master Security Groups vs NACLs and Route 53 DNS records.
- **Resources**:
    - [Domain Name System (DNS) Basics (Video)](https://www.youtube.com/watch?v=1cS2Nx7sxOM)
    - [Amazon Route 53 Basics Tutorial (Video)](https://www.youtube.com/watch?v=JRZiQFVWpi8)
    - [What Are NACLs in AWS? (Video)](https://www.youtube.com/watch?v=t4ZUhxBmVJM)
    - [AWS Security Groups Simply Explained (Video)](https://www.youtube.com/watch?v=uYDT2SsHImQ)
    - [Security Groups vs. NACLs: What’s the Difference? (Video)](https://www.youtube.com/watch?v=JWoNu2Mtpdg)
- **Related Lab**: [Lab 5: Secure Networking (NACLs/SGs)](labs/05-Advanced_EC2_VPC.md)

---

## Module 6: AWS SDK for Python (Boto3)
*Automating AWS with Python code.*

- **Objectives**: Setup Boto3, understand the difference between Resource and Client, and automate infrastructure tasks.
- **Resources**:
    - [Boto3 Documentation (Official Docs)](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
    - [Intro to Boto3 - Python SDK for AWS (Video)](https://www.youtube.com/watch?v=tDchQ0nv7Q4)
    - [Python Boto3 Tutorial: Getting Started (Video)](https://www.youtube.com/watch?v=kG-fLp9BTRo)
    - [Paginators and Waiters in Boto3 (Video)](https://www.youtube.com/watch?v=_XUwqWjey3I)
    - [Boto3: AWS SDK for Python (Medium Article)](https://medium.com/featurepreneur/boto3-aws-sdk-for-python-e7391b9901c5)
    - [How to use Python with the AWS Boto3 SDK - Hands-On Introduction)](https://www.youtube.com/watch?v=QSDIKakB8qs)
- **Related Labs**:
    - [Lab 6: Python for AWS (Boto3)](labs/06-AWS_SDK_Boto3.md)
    - [Lab 7: Automating AWS with Boto3](labs/07-Automation_Boto3.md)

---

## Module 7: Terraform Fundamentals
*Automating infrastructure with HashiCorp Terraform.*

- **Objectives**: Master Terraform HCL, providers, resources, and state management.
- **Resources**:
    - [What is Infrastructure as Code?](https://www.youtube.com/watch?v=zWw2wuiKd5o)
    - [What is Infrastructure as Code (IaC)?](https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac)
    - [Terraform in 100 Seconds](https://www.youtube.com/watch?v=tomUWcQ0P3k)
    - [Terraform Crash Course (Video)](https://www.youtube.com/watch?v=HmxkYNv1ksg)
    - [Intro to Terraform](https://developer.hashicorp.com/terraform/intro)
    - [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
    - [Terraform Basics](https://notes.kodekloud.com/docs/Terraform-Basics-Training-Course/Introduction/Course-Introduction/page)
- **Related Labs**:
    - [Lab 8: Terraform Fundamentals](labs/08-Intro_Terraform.md)
    - [Lab 9: Reusable Terraform Modules](labs/09-Terraform_Modules.md)
    - [Lab 10: Terraform State & Import](labs/10-Remote_State.md)

---

## Module 8: Terragrunt & Advanced DRY
*Scaling IaC with the Terragrunt DRY wrapper.*

- **Objectives**: Understand Terragrunt's DRY principle, remote state management, and multi-account orchestration.
- **Resources**:
    - [Terragrunt for Beginners](https://notes.kodekloud.com/docs/Terragrunt-for-Beginners/Introduction/Course-Introduction)
- **Related Labs**:
    - [Lab 11: Terragrunt Basics](labs/11-Intro_Terragrunt.md)
    - [Lab 12: Complex Terragrunt Stacks](labs/12-Advanced_Terragrunt.md)
    - [Lab 13: Terragrunt Import](labs/13-Terragrunt_Import.md)

---

## 🏆 Capstone Projects

*End-to-end projects that combine skills from all modules.*

| Capstone | Focus | Difficulty | Prerequisites |
| :--- | :--- | :--- | :--- |
| [Capstone: Architect the Cloud](labs/Project_Capstone_Architecture.md) | Design, build, and resilience-test a production HA architecture on AWS | Advanced | Labs 1–7 |
| [Capstone: IaC Mastery](labs/Project_Capstone_IaC.md) | Author Terraform modules from scratch, wire with Terragrunt, master state management | Advanced | Labs 8–13 |
| [Capstone: The Great Migration](labs/Project_Capstone_Import.md) | Discover legacy infrastructure via CLI/SDK and codify it into Terragrunt with `import` blocks | Advanced | Labs 1–13 |

