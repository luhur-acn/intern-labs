# Capstone Project: Infrastructure as Code Mastery

| Difficulty | Est. Time | Prerequisites |
|------------|-----------|---------------|
| Advanced | 4–5 Hours | Labs 8–13 |

## 🎯 Vision

You are an **IaC Engineer** building a platform team's foundational infrastructure repository from the ground up. A company is moving from manual Console deployments to a fully automated, pull-request-driven infrastructure workflow. Your job is to:

1. **Author reusable Terraform modules** from scratch (no community modules allowed).
2. **Wire them together** using a Terragrunt DRY multi-environment structure.
3. **Prove state integrity** by safely migrating, moving, and recovering Terraform state.
4. **Simulate a production deployment pipeline** by running ordered, layered plans and applies.

> **Pluralsight Sandbox Note**: All AWS services used here (VPC, EC2, S3, IAM, DynamoDB) are supported in the Pluralsight sandbox. All Terraform and Terragrunt tools need to be installed in the sandbox shell. Installation commands are provided.

---

## 🗺️ Target Repository Structure

You will build **two environments** (dev and prod) from a single set of reusable modules using Terragrunt dependency blocks to wire outputs as inputs.

```mermaid
graph LR
    %% ── Styles ──────────────────────────────────────────────────────────────
    classDef root    fill:none,stroke:#c85581,stroke-width:2px;
    classDef backend fill:none,stroke:#3b48cc,stroke-width:2px;
    classDef envNode fill:none,stroke:#8c4fff,stroke-width:1.5px,stroke-dasharray:4 3;
    classDef mod     fill:none,stroke:#ff9900,stroke-width:1px;

    %% ── Root & Backend ───────────────────────────────────────────────────────
    Root["🗂️ root.hcl\nRemote State + Provider"]
    Backend[("🗄️ S3 + DynamoDB\nState Backend")]
    Root --> Backend

    %% ── DEV ENVIRONMENT ──────────────────────────────────────────────────────
    subgraph Dev ["🔵 DEV ENVIRONMENT"]
        direction TB
        DevEnv["📄 dev/env.hcl"]
        D_VPC["🌐 vpc"]
        D_SG["🔒 security-groups"]
        D_EC2["🖥️ ec2"]
        D_S3["🪣 s3"]

        DevEnv --> D_VPC & D_S3
        D_VPC -->|dep| D_SG
        D_VPC -->|dep| D_EC2
        D_SG  -->|dep| D_EC2
    end

    %% ── PROD ENVIRONMENT ─────────────────────────────────────────────────────
    subgraph Prod ["🟠 PROD ENVIRONMENT"]
        direction TB
        ProdEnv["📄 prod/env.hcl"]
        P_VPC["🌐 vpc"]
        P_SG["🔒 security-groups"]
        P_EC2["🖥️ ec2"]
        P_S3["🪣 s3"]

        ProdEnv --> P_VPC & P_S3
        P_VPC -->|dep| P_SG
        P_VPC -->|dep| P_EC2
        P_SG  -->|dep| P_EC2
    end

    %% ── Root connections ─────────────────────────────────────────────────────
    Root --> DevEnv
    Root --> ProdEnv

    %% ── Class Assignments ────────────────────────────────────────────────────
    class Root root;
    class Backend backend;
    class DevEnv,ProdEnv envNode;
    class D_VPC,D_SG,D_EC2,D_S3,P_VPC,P_SG,P_EC2,P_S3 mod;
```

---

## 📋 Technical Specifications

---

### Phase 0: Environment Setup

#### 🛠️ Install Required Tools

> Run these commands in your sandbox shell. All installs are local to your session.

```bash
# Install Terraform v1.7
curl -Lo /tmp/tf.zip https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip /tmp/tf.zip -d /usr/local/bin/

# Install Terragrunt v0.55
curl -Lo /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.21/terragrunt_linux_amd64
chmod +x /usr/local/bin/terragrunt

# Verify
terraform version
terragrunt --version
```

#### Create the State Backend (Manual — One Time Only)

```bash
# Create the S3 state bucket
aws s3api create-bucket \
  --bucket iac-capstone-tfstate-[yourname] \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket iac-capstone-tfstate-[yourname] \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket iac-capstone-tfstate-[yourname] \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name iac-capstone-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

> **Why create this manually?** The state backend itself cannot be managed by Terraform — it must exist before Terraform can store its own state. This is a common real-world bootstrapping pattern called "chicken-and-egg state".

---

### Phase 1: Author the Terraform Modules

> **Rule**: You may NOT use any modules from the Terraform Registry (e.g., `terraform-aws-modules`). Every module must be authored by you. This phase tests your understanding of Terraform resource syntax, variable design, and output contracts.

#### 📦 Deliverables
- `modules/vpc/` — fully authored VPC module
- `modules/security-groups/` — SG module
- `modules/ec2/` — EC2 instance module
- `modules/s3/` — S3 bucket module

---

#### 1.1 Module: VPC (`modules/vpc/`)

**Required files**: `main.tf`, `variables.tf`, `outputs.tf`

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| VPC | `aws_vpc` | 1 per module call |
| Public Subnets | `aws_subnet` | `for_each` over `var.public_subnet_cidrs` |
| Private Subnets | `aws_subnet` | `for_each` over `var.private_subnet_cidrs` |
| Internet Gateway | `aws_internet_gateway` | 1 per module call |
| NAT Gateway | `aws_nat_gateway` | 1 per module call |
| Elastic IP (for NAT) | `aws_eip` | 1 per module call |
| Public Route Table | `aws_route_table` | 1 per module call |
| Private Route Table | `aws_route_table` | 1 per module call |
| Public RT Associations | `aws_route_table_association` | `for_each` — 1 per public subnet |
| Private RT Associations | `aws_route_table_association` | `for_each` — 1 per private subnet |

**Required Variables** (`variables.tf`):

```hcl
variable "vpc_cidr"             { type = string }
variable "public_subnet_cidrs"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones"   { type = list(string) }
variable "environment"          { type = string }
variable "tags"                 { type = map(string), default = {} }
```

> **Scalability**: The number of subnets is driven entirely by the length of `public_subnet_cidrs` and `private_subnet_cidrs`. Pass 2, 3, or 6 CIDRs — the module creates that many subnets without code changes.

**`for_each` pattern hint** (in `main.tf`):

```hcl
locals {
  public_subnets = zipmap(var.availability_zones, var.public_subnet_cidrs)
  private_subnets = zipmap(var.availability_zones, var.private_subnet_cidrs)
}

resource "aws_subnet" "public" {
  for_each          = local.public_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.environment}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = merge(var.tags, {
    Name = "${var.environment}-private-${each.key}"
    Tier = "private"
  })
}
```

**Required Outputs** (`outputs.tf`) — these will be consumed by other modules via Terragrunt `dependency` blocks:

```hcl
output "vpc_id"             { value = aws_vpc.this.id }
output "public_subnet_ids"  { value = values(aws_subnet.public)[*].id }
output "private_subnet_ids" { value = values(aws_subnet.private)[*].id }
output "public_rt_id"       { value = aws_route_table.public.id }
output "private_rt_id"      { value = aws_route_table.private.id }
```

> **Note**: Outputs use `values(...)[*].id` so they automatically scale — adding a third AZ to the input lists produces a third subnet ID in the output without any code change.

**Constraint**: Use `for_each` for subnet creation — not individual resource blocks for each subnet. Route table associations must also use `for_each`.

---

#### 1.2 Module: Security Groups (`modules/security-groups/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| Security Groups | `aws_security_group` | `for_each` over `var.security_groups` map keys |
| Ingress Rules | `aws_vpc_security_group_ingress_rule` | `for_each` — flattened from each SG's `ingress_rules` list |
| Egress Rules | `aws_vpc_security_group_egress_rule` | `for_each` — 1 allow-all per SG |

**Design requirement**: Do not use inline `ingress` / `egress` blocks inside the `aws_security_group` resource. Use the separate `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` resources instead. Explain in a comment why this avoids Terraform conflicts.

**Required Variables**:

```hcl
variable "vpc_id"      { type = string }
variable "environment" { type = string }
variable "tags"        { type = map(string), default = {} }

variable "security_groups" {
  description = "Map of security groups to create. Each key becomes the SG name suffix."
  type = map(object({
    description   = string
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_ipv4   = string
    }))
  }))
}
```

> **Scalability**: Define as many security groups as needed (e.g., `ec2`, `alb`, `rds`), each with an arbitrary number of ingress rules. Adding a new SG or rule is a data change, not a code change.

**`for_each` pattern hint** (in `main.tf`):

```hcl
# --- Security Groups (one per map key) ---
resource "aws_security_group" "this" {
  for_each    = var.security_groups
  name        = "${var.environment}-${each.key}-sg"
  description = each.value.description
  vpc_id      = var.vpc_id
  tags = merge(var.tags, { Name = "${var.environment}-${each.key}-sg" })
}

# --- Ingress Rules (flatten SG × rules) ---
locals {
  ingress_rules = flatten([
    for sg_key, sg in var.security_groups : [
      for idx, rule in sg.ingress_rules : {
        sg_key      = sg_key
        rule_key    = "${sg_key}-${idx}"
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        ip_protocol = rule.ip_protocol
        cidr_ipv4   = rule.cidr_ipv4
      }
    ]
  ])
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for r in local.ingress_rules : r.rule_key => r }

  security_group_id = aws_security_group.this[each.value.sg_key].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
}

# --- Egress: allow all outbound per SG ---
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each          = var.security_groups
  security_group_id = aws_security_group.this[each.key].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}
```

**Required Outputs**:

```hcl
# Returns a map: { "ec2" = "sg-abc...", "alb" = "sg-def..." }
output "security_group_ids" {
  value = { for k, sg in aws_security_group.this : k => sg.id }
}
```

---

#### 1.3 Module: EC2 (`modules/ec2/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| EC2 Instances | `aws_instance` | `for_each` over `var.instances` map keys |
| IAM Role | `aws_iam_role` | 1 shared role per module call |
| IAM Instance Profile | `aws_iam_instance_profile` | 1 shared profile per module call |
| IAM Policy Attachment (SSM) | `aws_iam_role_policy_attachment` | 1 per module call |

**IAM Requirement**: The EC2 instances must be launched with a **shared IAM instance profile** that attaches the `AmazonSSMManagedInstanceCore` managed policy. This allows connection via Session Manager without a key pair. One IAM role is shared across all instances in the module call — this is best practice (avoid IAM role sprawl).

**Required Variables**:

```hcl
variable "environment"     { type = string }
variable "tags"            { type = map(string), default = {} }

variable "instances" {
  description = "Map of instances to create. Each key becomes the instance name suffix."
  type = map(object({
    ami_id             = string
    instance_type      = string
    subnet_id          = string
    security_group_ids = list(string)
    user_data          = optional(string, "")
  }))
}
```

> **Scalability**: Define as many EC2 instances as needed (e.g., `web`, `app`, `worker`), each with independent AMI, instance type, subnet placement, and security groups. Adding a new instance is a data change, not a code change.

**`for_each` pattern hint** (in `main.tf`):

```hcl
resource "aws_instance" "this" {
  for_each = var.instances

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.this.name
  user_data              = each.value.user_data != "" ? each.value.user_data : null

  tags = merge(var.tags, {
    Name = "${var.environment}-${each.key}"
  })
}
```

**Required Outputs**:

```hcl
# Returns maps: { "web" = "i-abc...", "app" = "i-def..." }
output "instance_ids" {
  value = { for k, inst in aws_instance.this : k => inst.id }
}
output "private_ips" {
  value = { for k, inst in aws_instance.this : k => inst.private_ip }
}
output "iam_role_arn" { value = aws_iam_role.this.arn }
```

**Constraint**: Do not hardcode any AMI ID or instance type. All values must come from the `instances` map.

---

#### 1.4 Module: S3 (`modules/s3/`)

**Resources this module must manage**:

| Resource | Terraform Type | Scaling |
| :--- | :--- | :--- |
| S3 Buckets | `aws_s3_bucket` | `for_each` over `var.buckets` map keys |
| Block Public Access | `aws_s3_bucket_public_access_block` | `for_each` — 1 per bucket |
| Encryption Config | `aws_s3_bucket_server_side_encryption_configuration` | `for_each` — 1 per bucket |
| Versioning Config | `aws_s3_bucket_versioning` | `for_each` — 1 per bucket |
| Lifecycle Rule | `aws_s3_bucket_lifecycle_configuration` | `for_each` — 1 per bucket |
| Random ID Suffix | `random_id` | `for_each` — 1 per bucket |

**Required Variables**:

```hcl
variable "environment" { type = string }
variable "tags"        { type = map(string), default = {} }

variable "buckets" {
  description = "Map of S3 buckets to create. Each key becomes the bucket name prefix."
  type = map(object({
    versioning_enabled     = optional(bool, true)
    noncurrent_expiry_days = optional(number, 30)
  }))
}
```

> **Scalability**: Define as many buckets as needed (e.g., `app-artifacts`, `app-logs`, `backups`), each with independent versioning and lifecycle settings. Adding a new bucket is a data change, not a code change.

**Design requirement**: The bucket name must be constructed **inside the module** using `"${each.key}-${var.environment}-${random_id.suffix[each.key].hex}"` to ensure global uniqueness.

**`for_each` pattern hint** (in `main.tf`):

```hcl
resource "random_id" "suffix" {
  for_each    = var.buckets
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  bucket   = "${each.key}-${var.environment}-${random_id.suffix[each.key].hex}"
  tags     = merge(var.tags, { Name = "${each.key}-${var.environment}" })
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets
  bucket   = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = each.value.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Repeat for_each pattern for: public_access_block, encryption, lifecycle
```

**Required Outputs**:

```hcl
# Returns maps: { "app-artifacts" = "app-artifacts-dev-a1b2c3d4", ... }
output "bucket_names" {
  value = { for k, b in aws_s3_bucket.this : k => b.id }
}
output "bucket_arns" {
  value = { for k, b in aws_s3_bucket.this : k => b.arn }
}
```

---

#### 1.5 Module Validation

Before wiring modules into Terragrunt, validate each module in isolation using a temporary `test/` directory. This is a standard practice for module development.

```bash
# Create a temporary test directory for each module
mkdir -p test/vpc && cat > test/vpc/main.tf <<'EOF'
module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = "10.99.0.0/16"
  public_subnet_cidrs  = ["10.99.1.0/24", "10.99.3.0/24", "10.99.5.0/24"]
  private_subnet_cidrs = ["10.99.2.0/24", "10.99.4.0/24", "10.99.6.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment          = "test"
}
EOF

cd test/vpc
terraform init
terraform validate
terraform plan
terraform destroy -auto-approve  # Clean up test resources
cd ../..
```

> **Scalability test**: The VPC test uses 3 AZs to prove the module scales beyond 2. If you change the lists to 1 or 4 AZs, the plan should still succeed.

Repeat for each module with appropriate scalable inputs:

```bash
# Security Groups — test with multiple SGs and rules
mkdir -p test/sg && cat > test/sg/main.tf <<'EOF'
module "security_groups" {
  source      = "../../modules/security-groups"
  vpc_id      = "vpc-test123"  # Use a real VPC ID or run after VPC apply
  environment = "test"
  security_groups = {
    ec2 = {
      description = "EC2 instances"
      ingress_rules = [
        { description = "SSH",  from_port = 22,  to_port = 22,  ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/8" },
        { description = "HTTP", from_port = 80,  to_port = 80,  ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
    }
    alb = {
      description = "Load balancer"
      ingress_rules = [
        { description = "HTTP",  from_port = 80,  to_port = 80,  ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
        { description = "HTTPS", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
    }
  }
}
EOF
```

Do not proceed to Phase 2 until all modules pass `terraform validate`.

---

### Phase 2: Terragrunt Multi-Environment Wiring

Now wire your modules together with Terragrunt. Use `dependency` blocks to pass outputs between stacks without hardcoding any IDs.

#### 📦 Deliverables
- Complete `infrastructure/` directory tree as specified below.
- `terragrunt run-all plan` output showing resources to be created across all environments.
- `terragrunt run-all apply` output confirming all resources created successfully.

---

#### 2.1 Full Directory Structure

```text
infrastructure/
├── root.hcl
├── dev/
│   ├── env.hcl
│   ├── vpc/
│   │   └── terragrunt.hcl
│   ├── security-groups/
│   │   └── terragrunt.hcl
│   ├── ec2/
│   │   └── terragrunt.hcl
│   └── s3/
│       └── terragrunt.hcl
└── prod/
    ├── env.hcl
    ├── vpc/
    │   └── terragrunt.hcl
    ├── security-groups/
    │   └── terragrunt.hcl
    ├── ec2/
    │   └── terragrunt.hcl
    └── s3/
        └── terragrunt.hcl
```

---

#### 2.2 `root.hcl`

```hcl
locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project     = "iac-capstone"
  region      = "us-east-1"
  aws_account = get_aws_account_id()
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "iac-capstone-tfstate-[yourname]"
    key            = "${local.project}/${local.environment}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "iac-capstone-tfstate-lock"
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

provider "random" {}
EOF
}
```

---

#### 2.3 `dev/env.hcl`

This file contains only **shared, environment-level** variables. Resource-specific inputs live in each stack's `terragrunt.hcl`.

```hcl
locals {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  ami_id               = "ami-0c02fb55956c7d316"  # Amazon Linux 2023 us-east-1
}
```

---

#### 2.4 `dev/vpc/terragrunt.hcl`

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
  vpc_cidr             = local.env.vpc_cidr
  public_subnet_cidrs  = local.env.public_subnet_cidrs
  private_subnet_cidrs = local.env.private_subnet_cidrs
  availability_zones   = local.env.availability_zones
  environment          = local.env.environment
}
```

---

#### 2.5 `dev/security-groups/terragrunt.hcl`

Use a `dependency` block to receive the VPC ID from the VPC stack. Resource-specific inputs are defined **directly in this file**, not in `env.hcl`.

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//security-groups"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = local.env.environment

  # Define security groups and their rules here
  security_groups = {
    ec2 = {
      description = "EC2 instance traffic"
      ingress_rules = [
        { description = "SSH",  from_port = 22, to_port = 22, ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/8" },
        { description = "HTTP", from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
      ]
    }
  }
}
```

> **Scalability**: To add a new SG (e.g., `alb`, `rds`) or new ingress rules, edit this file directly. Each resource stack owns its own input definitions.

---

#### 2.6 `dev/ec2/terragrunt.hcl`

Use **two** `dependency` blocks — one for the VPC (subnet IDs) and one for the security groups (SG IDs map). The `instances` map is defined **directly in this file** with dependency outputs resolved inline.

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

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111"]
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

  # Define instances directly in this stack's config
  instances = {
    web = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.micro"
      subnet_id          = dependency.vpc.outputs.private_subnet_ids[0]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      user_data          = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        echo "<h1>IaC Capstone - ${local.env.environment} - web</h1>" > /var/www/html/index.html
        systemctl start httpd && systemctl enable httpd
      EOF
    }
  }
}
```

> **Scalability**: To add more instances, add keys to `instances` directly in this file. Each instance can target a different subnet or security group.

---

#### 2.7 `dev/s3/terragrunt.hcl`

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../modules//s3"
}

inputs = {
  environment = local.env.environment

  # Define buckets directly in this stack's config
  buckets = {
    app-artifacts = {
      versioning_enabled     = true
      noncurrent_expiry_days = 30
    }
  }
}
```

> **Scalability**: To add more buckets, add keys to `buckets` directly in this file. S3 has no dependencies on VPC or SGs.

---

#### 2.8 Task: Wire `prod/` Independently

Now replicate the same wiring for `prod/` using `prod/env.hcl` with CIDR `10.1.0.0/16`. The `prod` configs must be **entirely independent** — no dependency or reference to the `dev` stacks.

**`prod/env.hcl`** — only shared, environment-level variables:

```hcl
locals {
  environment          = "prod"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.3.0/24", "10.1.5.0/24"]
  private_subnet_cidrs = ["10.1.2.0/24", "10.1.4.0/24", "10.1.6.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  ami_id               = "ami-0c02fb55956c7d316"
}
```

Resource-specific inputs are defined in each stack's `terragrunt.hcl`. For example, `prod/ec2/terragrunt.hcl` would define:

```hcl
# (same dependency blocks as dev/ec2/terragrunt.hcl)

inputs = {
  environment = local.env.environment

  instances = {
    web-1 = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.small"
      subnet_id          = dependency.vpc.outputs.private_subnet_ids[0]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      user_data          = <<-EOF
        #!/bin/bash
        yum update -y && yum install -y httpd
        echo "<h1>IaC Capstone - prod - web-1</h1>" > /var/www/html/index.html
        systemctl start httpd && systemctl enable httpd
      EOF
    }
    web-2 = {
      ami_id             = local.env.ami_id
      instance_type      = "t3.small"
      subnet_id          = dependency.vpc.outputs.private_subnet_ids[1]
      security_group_ids = [dependency.security_groups.outputs.security_group_ids["ec2"]]
      user_data          = <<-EOF
        #!/bin/bash
        yum update -y && yum install -y httpd
        echo "<h1>IaC Capstone - prod - web-2</h1>" > /var/www/html/index.html
        systemctl start httpd && systemctl enable httpd
      EOF
    }
  }
}
```

And `prod/s3/terragrunt.hcl` would define:

```hcl
inputs = {
  environment = local.env.environment
  buckets = {
    app-artifacts = { versioning_enabled = true,  noncurrent_expiry_days = 90 }
    app-logs      = { versioning_enabled = false, noncurrent_expiry_days = 14 }
  }
}
```

> **Key difference**: Prod uses 3 AZs, 2 EC2 instances, an extra HTTPS rule, 2 S3 buckets, and longer lifecycle retention — all configured per resource stack, no code changes.
>
> **Validation**: Run `terragrunt run-all validate` from within `infrastructure/dev/` only. Confirm it does not trigger any `prod` runs.

---

#### 2.9 Deploy Both Environments

```bash
# From infrastructure/
terragrunt run-all apply
```

Observe the ordered apply — Terragrunt resolves the dependency graph and applies stacks in the correct order (VPC → SGs → EC2 → S3). Document the apply order from the log.

> **Observe the scaling difference**: Dev should create fewer resources than Prod (fewer subnets, fewer instances, fewer buckets). Both environments use the exact same module code — only each stack's `terragrunt.hcl` differs.

---

### Phase 3: State Management Deep Dive

> **This phase tests your ability to safely manipulate Terraform state.** You will perform operations that are dangerous if done incorrectly, and you will recover from a deliberately induced state disaster.

#### 📦 Deliverables
- State inspection outputs proving resource addresses.
- `state mv` log and subsequent "No changes" plan.
- Force-unlock log with recovered Lock ID.
- State export/import proof showing successful recovery.

---

#### 3.1 Inspect & Understand Your State

From within `infrastructure/dev/ec2/`:

```bash
# List all resources currently in state
terragrunt state list

# Show full details of a specific EC2 instance (note the for_each key)
terragrunt state show 'module.ec2.aws_instance.this["web"]'

# Pull the raw state file to inspect it
terragrunt state pull | jq '.resources[].type' | sort | uniq
```

**Task**: Answer the following by reading the state output:
1. What is the `id` of the IAM instance profile in the state?
2. What `ami` was used? Is it the same as the AMI from `env.hcl`?
3. How many total resources are tracked in the `dev/ec2` state file?

---

#### 3.2 State Move (Refactoring)

Imagine the IaC team decided to rename the EC2 Terraform module's internal resource from `aws_instance.this` to `aws_instance.main`. Without a `state mv`, Terraform would destroy and recreate the instances.

**Simulate this refactor**:

1. In your module's `main.tf`, rename `resource "aws_instance" "this"` → `resource "aws_instance" "main"`.
2. Update all references (`outputs.tf`, etc.) to use `aws_instance.main`.
3. **Before** running plan, move the state for **each keyed instance**:
   ```bash
   terragrunt state mv \
     'module.ec2.aws_instance.this["web"]' \
     'module.ec2.aws_instance.main["web"]'
   ```
   > Repeat for every key in your `instances` map.
4. Run `terragrunt plan`. Confirm output shows: `No changes. Your infrastructure matches the configuration.`
5. Rename back (`main` → `this`) and perform the `state mv` in reverse.

**Document**: The exact `state mv` command you ran and the "No changes" plan output.

---

#### 3.3 State Locking: Force-Unlock Recovery

You will deliberately simulate a stuck state lock and recover it.

1. Start a `terragrunt apply` in `dev/vpc/`:
   ```bash
   terragrunt apply &
   ```
2. Immediately kill the process before it finishes:
   ```bash
   kill %1
   ```
3. Attempt to run `terragrunt plan` in the same folder. It will fail with a lock error. **Copy the Lock ID from the error message.**
4. Unlock:
   ```bash
   terragrunt force-unlock [LOCK-ID]
   ```
5. Confirm `terragrunt plan` runs successfully after unlock.

**Document**: The full lock error message (including Lock ID) and the `force-unlock` command you used.

---

#### 3.4 State Export, Corrupt & Recover

This simulates a disaster recovery scenario.

1. Export the current clean state:
   ```bash
   terragrunt state pull > dev_ec2_backup.tfstate
   ```
2. **Corrupt the live state** by pushing an empty state (simulate accidental deletion):
   ```bash
   echo '{"version": 4, "terraform_version": "1.7.5", "serial": 999, "lineage": "", "outputs": {}, "resources": []}' | terragrunt state push /dev/stdin
   ```
3. Run `terragrunt plan`. Observe that Terraform now wants to **re-create all resources** (state is empty, but real resources exist).
4. **Recover** by pushing the backup state:
   ```bash
   terragrunt state push dev_ec2_backup.tfstate
   ```
5. Run `terragrunt plan` again. Confirm it shows "No changes."

**Document**: The plan output from step 3 (showing re-create) and the plan output from step 5 (showing No changes).

---

### Phase 4: Pipeline Simulation & Policy Enforcement

Simulate how a real CI/CD pipeline would handle infrastructure changes — with ordered approvals and policy enforcement.

#### 📦 Deliverables
- `plan_dev.txt` and `plan_prod.txt`: Saved plan files (binary format, then converted to human-readable with `terraform show`).
- `diff_report.md`: A table comparing what changed in dev vs. prod.
- `policy_check.sh`: A Bash script that fails if a plan contains any `destroy` actions.

---

#### 4.1 Generate and Save Plans

```bash
# Dev
cd infrastructure/dev/ec2
terragrunt plan -out=plan_dev.tfplan
terraform show -no-color plan_dev.tfplan > plan_dev.txt

# Prod
cd ../../prod/ec2
terragrunt plan -out=plan_prod.tfplan
terraform show -no-color plan_prod.tfplan > plan_prod.txt
```

---

#### 4.2 The Policy Gate: No Destroy Allowed

Write a Bash script that reads a plan file and **exits with code 1** if any resource is marked for destruction. This simulates a CI policy gate.

```bash
#!/bin/bash
# policy_check.sh — Fails if plan contains any destroy actions
PLAN_FILE="${1:-plan_dev.txt}"

if grep -q "# .* will be destroyed" "$PLAN_FILE"; then
  echo "❌ POLICY VIOLATION: Plan contains destroy actions. Aborting."
  grep "# .* will be destroyed" "$PLAN_FILE"
  exit 1
else
  echo "✅ Policy check passed. No destroy actions found."
  exit 0
fi
```

**Test the script**:
1. Run it against your current dev plan: `bash policy_check.sh plan_dev.txt` — should pass.
2. Modify your EC2 module to force a replacement (e.g., change `ami_id` to a different AMI). Run plan, save it, and run the policy check — it should detect the destroy and fail.
3. Revert the AMI change.

---

#### 4.3 Ordered Layered Apply

In a real pipeline, you apply environment layers in order (lowest risk first):

```bash
# Stage 1: Apply dev only
cd infrastructure/dev && terragrunt run-all apply

# Stage 2: Smoke test dev (substitute real ALB/instance verification)
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

STATE=$(aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --query "InstanceStatuses[0].InstanceState.Name" --output text 2>/dev/null || echo "pending")
echo "Dev instance state: $STATE"

# Stage 3: Apply prod only if dev passed
if [ "$STATE" = "running" ]; then
  echo "✅ Dev smoke test passed. Promoting to prod..."
  cd ../prod && terragrunt run-all apply
else
  echo "❌ Dev smoke test failed. Halting prod deploy."
  exit 1
fi
```

---

#### 4.4 Tag Drift Detection

Simulate a scenario where someone manually added a tag via the Console (tag drift). Detect and remediate it via Terraform.

1. Manually add a tag to your dev EC2 instance in the Console: Key=`Manual`, Value=`TrueStory`.
2. Run `terragrunt plan` in `dev/ec2/`. Observe that Terraform **detects the drift** and plans to remove the manual tag.
3. Document: Does Terraform remove the manually added tag? Why or why not? (Hint: check `default_tags` behavior with `ignore_tags`.)
4. Add `ignore_changes = [tags["Manual"]]` to the EC2 resource's lifecycle block in your module.
5. Run plan again. Confirm the manual tag is now **ignored** (plan shows No changes for tags).

---

## 🧹 Cleanup

```bash
# Destroy all managed resources (both environments)
cd infrastructure/
terragrunt run-all destroy

# Destroy the state backend (manually)
aws dynamodb delete-table --table-name iac-capstone-tfstate-lock

aws s3 rm s3://iac-capstone-tfstate-[yourname] --recursive
aws s3 rb s3://iac-capstone-tfstate-[yourname]
```

---

## ✅ Final Deliverable Checklist

| # | Deliverable | Description |
| :--: | :--- | :--- |
| 1 | `modules/vpc/` | Fully authored VPC module with `for_each` for dynamic subnets |
| 2 | `modules/security-groups/` | SG module using nested `for_each` — multiple SGs with dynamic ingress rules |
| 3 | `modules/ec2/` | EC2 module with `for_each` instances + shared IAM role + SSM instance profile |
| 4 | `modules/s3/` | S3 module with `for_each` buckets, encryption, versioning, lifecycle, and random suffix |
| 5 | Module Validation Logs | `terraform validate` + `terraform plan` passing for each module with scalable inputs |
| 6 | `infrastructure/` (Git repo) | Full DRY Terragrunt tree with `dependency` blocks wiring all map-based outputs |
| 7 | `terragrunt run-all apply` Log | Successful ordered apply across both environments (dev = fewer resources, prod = more) |
| 8 | State Deep Dive Answers | Answers to §3.1 Q1–Q3 with CLI output (note `for_each`-keyed resource addresses) |
| 9 | `state mv` + "No changes" Log | §3.2 state move of keyed resources + plan confirming no resource replacement |
| 10 | Force-Unlock Log | §3.3 lock error message + `force-unlock` command + successful plan |
| 11 | State Corrupt & Recovery Log | §3.4 corrupted plan (showing re-create) + recovered plan (No changes) |
| 12 | `policy_check.sh` | Script that detects destroy actions + proof it fails on a destructive plan |
| 13 | `plan_dev.txt` & `plan_prod.txt` | Human-readable plan files from §4.1 |
| 14 | Tag Drift Report | §4.4 — drift detected plan + `ignore_changes` fix + "No changes" plan |
