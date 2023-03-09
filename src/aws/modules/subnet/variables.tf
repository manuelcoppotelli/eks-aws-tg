variable "environment" {
  type        = string
  description = "The environment"
}

variable "tags" {
  type        = map(string)
  description = "The property to which tagging the resources"
  default     = {}
}

variable "name" {
  type        = string
  description = "The name of the subnets"
  default     = "backend"
}

variable "zone_ids" {
  type        = list(string)
  description = ""
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR of the VPC"
}

variable "newbits" {
  type        = string
  description = "The number of additional bits with which to extend the VPC CIDR"
}

variable "displacement" {
  type        = string
  description = "The displacement after the extended CIDR"
}
