variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "project" {
  type    = string
  default = "capstone"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "target_groups" {
  type = map(object({
    port                               = number
    protocol                           = string
    target_type                        = string
    health_check_path                  = optional(string, "/")
    healthy_threshold                  = optional(number, 3)
    unhealthy_threshold                = optional(number, 3)
    interval                           = optional(number, 30)
    timeout                            = optional(number, 5)
    matcher                            = optional(string, "200")
    proxy_protocol_v2                  = optional(bool)
    load_balancing_algorithm_type      = optional(string)
    load_balancing_anomaly_mitigation  = optional(string)
    load_balancing_cross_zone_enabled  = optional(string)
    lambda_multi_value_headers_enabled = optional(bool)
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
  }))
}
