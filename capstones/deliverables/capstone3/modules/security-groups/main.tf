# modules/security-groups/main.tf
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = "${var.project}-${var.environment}-${each.key}-sg" # Ditambah prefix project agar match AWS
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-${each.key}-sg" })
}

locals {
  # Flattening ingress rules for for_each
  ingress_rules = flatten([
    for sg_key, sg in var.security_groups : [
      for idx, rule in sg.ingress_rules : merge(rule, {
        sg_key  = sg_key
        rule_id = "${sg_key}-ingress-${idx}"
      })
    ]
  ])
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for r in local.ingress_rules : r.rule_id => r }

  security_group_id = aws_security_group.this[each.value.sg_key].id
  description       = lookup(each.value, "description", null)
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = lookup(each.value, "cidr_ipv4", null)

  # Logika untuk mengambil ID SG jika menggunakan source_security_group_key
  referenced_security_group_id = lookup(each.value, "source_security_group_key", null) != null ? aws_security_group.this[each.value.source_security_group_key].id : lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = var.security_groups

  security_group_id = aws_security_group.this[each.key].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
