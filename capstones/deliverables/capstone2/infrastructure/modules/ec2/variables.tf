variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

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
