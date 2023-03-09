variable "dependencies" {
  description = "The dependenciens to import from other moduels"
  type = object({
    aws = map(any)
  })
}

variable "charts" {
  type = map(object({
    values     = string
    repository = string
    version    = string
  }))
  description = "The helm charts"
}

variable "environment" {
  type        = string
  description = "The environment"
  default     = "test"
}

variable "aws_region" {
  type        = string
  description = "AWS region to create resources. Default Stockholm"
  default     = "eu-north-1"
}

variable "identity" {
  description = "The cluster idenity"
  type = object({
    map_accounts = list(string)
    map_roles = list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    }))
    map_users = list(object({
      userarn  = string
      username = string
      groups   = list(string)
    }))
  })
  default = {
    map_accounts = []
    map_roles    = []
    map_users    = []
  }
}

variable "certificate_domain" {
  type        = string
  description = "The domain for which to emit the certificate"
}
