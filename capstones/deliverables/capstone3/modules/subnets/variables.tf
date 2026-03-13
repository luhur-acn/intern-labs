variable "vpc_id" {
  type = string
}

variable "igw_id" {
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

variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    tier              = string
    name              = string
  }))
}
