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

# --- Flatten Rules (SG × rules) ---
# We use separate resources for ingress and egress rules instead of inline blocks
# inside the aws_security_group resource.
# REASON: Inline blocks and separate resources for the same Security Group 
# are mutually exclusive. Mixing them causes Terraform to attempt to overwrite
# rules in a loop (conflict), where each apply fights to manage the same state.
# Separate resources are more flexible and prevent "state flapping".

locals {
  ingress_rules = flatten([
    for sg_key, sg in var.security_groups : [
      for idx, rule in sg.ingress_rules : {
        sg_key            = sg_key
        rule_key          = "${sg_key}-ingress-${idx}"
        description       = rule.description
        from_port         = rule.from_port
        to_port           = rule.to_port
        ip_protocol       = rule.ip_protocol
        cidr_ipv4         = rule.cidr_ipv4
        referenced_sg_key = rule.referenced_sg_key
      }
    ]
  ])

  egress_rules = flatten([
    for sg_key, sg in var.security_groups : [
      for idx, rule in sg.egress_rules : {
        sg_key            = sg_key
        rule_key          = "${sg_key}-egress-${idx}"
        description       = rule.description
        from_port         = rule.from_port
        to_port           = rule.to_port
        ip_protocol       = rule.ip_protocol
        cidr_ipv4         = rule.cidr_ipv4
        referenced_sg_key = rule.referenced_sg_key
      }
    ]
  ])
}

# --- Ingress Rules ---
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for r in local.ingress_rules : r.rule_key => r }

  security_group_id            = aws_security_group.this[each.value.sg_key].id
  description                  = each.value.description
  from_port                    = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_sg_key != null ? aws_security_group.this[each.value.referenced_sg_key].id : null
}

# --- Egress Rules ---
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for r in local.egress_rules : r.rule_key => r }

  security_group_id            = aws_security_group.this[each.value.sg_key].id
  description                  = each.value.description
  from_port                    = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_sg_key != null ? aws_security_group.this[each.value.referenced_sg_key].id : null
}
