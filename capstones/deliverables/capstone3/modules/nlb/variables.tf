variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
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

variable "subnet_mappings" {
  type = map(object({
    subnet_id     = string
    allocation_id = string
  }))
}

variable "target_groups" {
  type = map(object({
    port                               = number
    protocol                           = string
    target_type                        = string
    health_check_port                  = optional(string, "traffic-port")
    health_check_protocol              = optional(string, "HTTP")
    health_check_path                  = optional(string, "/")
    health_check_interval              = optional(number, 30)
    health_check_timeout               = optional(number, 5)
    healthy_threshold                  = optional(number, 3)
    unhealthy_threshold                = optional(number, 3)
    matcher                            = optional(string)
    deregistration_delay               = optional(number)
    proxy_protocol_v2                  = optional(bool)
    lambda_multi_value_headers_enabled = optional(bool)
    slow_start                         = optional(number)
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
    forward = optional(object({
      target_groups = optional(list(object({
        weight = number
      })), [])
      stickiness = optional(object({
        enabled  = bool
        duration = number
      }))
    }))
  }))
}
