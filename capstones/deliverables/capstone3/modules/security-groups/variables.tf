variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project" {
  type    = string
  default = "capstone"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "security_groups" {
  type = map(object({
    description = string
    ingress_rules = list(object({
      description                  = optional(string)
      from_port                    = number
      to_port                      = number
      ip_protocol                  = string
      cidr_ipv4                    = optional(string)
      referenced_security_group_id = optional(string)
      source_security_group_key    = optional(string)
    }))
  }))
}
