# --- Security Groups (one per map key) ---
resource "aws_security_group" "this" {
  for_each    = var.security_groups
  name        = "${var.environment}-${each.key}-sg"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.environment}-${each.key}-sg"
  })

  # Using lifecycle to ignore changes to tags if manual drift occurs (optional but good practice)
  # lifecycle {
  #   ignore_changes = [tags["Manual"]]
  # }
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

# Design requirement: Do not use inline ingress/egress blocks. 
# Use separate resources to avoid Terraform conflicts.
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
