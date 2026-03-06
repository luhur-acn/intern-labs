# --- Shared IAM Resources for EC2 ---
resource "aws_iam_role" "this" {
  name = "${var.environment}-ec2-shared-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.this.name

  tags = var.tags
}

# --- EC2 Instances ---
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

  # Best practice: root volume encryption (optional but good)
  root_block_device {
    encrypted = true
  }
}
