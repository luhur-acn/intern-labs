variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  description = "Map of security groups to create. Each key becomes the SG name suffix."
  type = map(object({
    description = string
    ingress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      ip_protocol       = string
      cidr_ipv4         = optional(string)
      referenced_sg_key = optional(string)
    }))
    egress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      ip_protocol       = string
      cidr_ipv4         = optional(string)
      referenced_sg_key = optional(string)
    }))
  }))
}
