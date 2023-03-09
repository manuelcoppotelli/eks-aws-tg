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

variable "tags" {
  type        = map(string)
  description = "The property to which tagging the resources"
  default = {
    CreatedBy = "Terraform"
  }
}

variable "cidrs" {
  type        = map(string)
  description = "The networking CIDRs"
}

variable "subnets" {
  type = map(object({
    newbits      = number
    displacement = number
  }))
  description = "The networking subnets with respect to VPC"
}

variable "certificate_domain" {
  type        = string
  description = "The domain for which to emit the certificate"
}

variable "control_plane" {
  description = "The control plane configuration"
  type = object({
    version = string
    public_access = object({
      enabled = bool
      cidrs   = list(string)
    })
    log = object({
      retention = number
      types     = list(string)
    })
  })
  default = {
    version = "1.25"
    public_access = {
      enabled = false
      cidrs   = []
    }
    log = {
      retention = 7
      types = [
        "api",
        "audit",
        "authenticator",
        "controllerManager",
        "scheduler"
      ]
    }
  }
}

variable "database" {
  description = "The configuration for postgresql database"
  type = object({
    instance_class          = string
    backup_retention_period = number
    backup_window           = string
    maintenance_window      = string
    log = object({
      retention = number
      exports   = list(string)
    })
    autoscaling = object({
      metric_type        = string
      min_capacity       = number
      max_capacity       = number
      scale_in_cooldown  = number
      scale_out_cooldown = number
      target_cpu         = number
      target_connections = number
    })
  })
  default = {
    instance_class          = "db.r6g.large"
    backup_retention_period = 7
    backup_window           = "04:00-06:00"
    maintenance_window      = "Mon:00:00-Mon:03:00"
    log = {
      retention = 7
      exports   = ["postgresql"]
    }
    autoscaling = {
      min_capacity       = 1
      max_capacity       = 10
      metric_type        = "RDSReaderAverageCPUUtilization"
      scale_in_cooldown  = 300
      scale_out_cooldown = 300
      target_cpu         = 70
      target_connections = 700 # 70% of db.r6g.large's default max_connections
    }
  }
}
