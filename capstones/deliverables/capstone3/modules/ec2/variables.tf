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

variable "instances" {
  type = map(object({
    ami_id             = string
    instance_type      = string
    subnet_id          = string
    security_group_ids = list(string)
    user_data          = optional(string, "")
  }))
}
