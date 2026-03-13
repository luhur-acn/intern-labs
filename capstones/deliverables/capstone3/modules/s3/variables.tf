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

variable "buckets" {
  type = map(object({
    versioning_enabled     = optional(bool, true)
    policy                 = optional(string)
    noncurrent_expiry_days = optional(number)
  }))
}
