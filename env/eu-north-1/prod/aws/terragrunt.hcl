# Automatically find the root terragrunt.hcl and inherit its configuration
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../src/aws//.?"
}

inputs = {
  tags = {
    CreatedBy   = "Terraform"
    Environment = "Prod"
    Owner       = "Manuel Coppotelli"
    Source      = "eks-aws-tf"
    CostCenter  = "CC01 - TECH"
  }

  cidrs = {
    vpc = "10.100.0.0/16"
  }

  subnets = {
    data = {
      newbits      = 8
      displacement = 0
    }
    back = {
      newbits      = 8
      displacement = 10
    }
    front = {
      newbits      = 8
      displacement = 20
    }
  }

  certificate_domain = "demo.manuelcoppotelli.me"

  control_plane = {
    version = "1.25"
    public_access = {
      enabled = true
      cidrs   = ["0.0.0.0/0"]
    }
    log = {
      retention = 1
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
