variable "vpc_cidr" {
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
