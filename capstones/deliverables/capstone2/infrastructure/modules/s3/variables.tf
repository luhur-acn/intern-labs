variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "buckets" {
  description = "Map of S3 buckets to create. Each key becomes the bucket name prefix."
  type = map(object({
    versioning_enabled     = optional(bool, true)
    noncurrent_expiry_days = optional(number, 30)
  }))
}
