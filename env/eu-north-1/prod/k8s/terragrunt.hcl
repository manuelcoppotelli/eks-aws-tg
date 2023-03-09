# Automatically find the root terragrunt.hcl and inherit its configuration
include {
  path = find_in_parent_folders()
}

dependency "aws" {
  config_path = "../aws"
}

terraform {
  source = "../../../../src/k8s//.?"
}

inputs = {
  certificate_domain = "demo.manuelcoppotelli.me"

  charts = {
    golang = {
      values     = file("values/golang.yaml")
      repository = "oci://594081136085.dkr.ecr.eu-north-1.amazonaws.com/"
      version    = "0.1.0"
    }
    php = {
      values     = file("values/php.yaml")
      repository = "oci://594081136085.dkr.ecr.eu-north-1.amazonaws.com/"
      version    = "0.1.0"
    }
    ingress = {
      values     = file("values/ingress_nginx.yaml")
      repository = "https://kubernetes.github.io/ingress-nginx"
      version    = "4.5.2"
    }
    karpenter = {
      values     = ""
      repository = "oci://public.ecr.aws/karpenter"
      version    = "v0.26.1"
    }
    load_balancer = {
      values     = ""
      repository = "https://aws.github.io/eks-charts"
      version    = "1.4.8"
    }
  }

  dependencies = {
    aws = {
      networking_vpc_id           = dependency.aws.outputs.networking_vpc_id
      cluster_name                = dependency.aws.outputs.cluster_name
      cluster_fargate             = dependency.aws.outputs.cluster_fargate
      karpenter_controller_name   = dependency.aws.outputs.karpenter_controller_name
      karpenter_node_profile_name = dependency.aws.outputs.karpenter_node_profile_name
      karpenter_node_role_name    = dependency.aws.outputs.karpenter_node_role_name
      karpenter_interruption_name = dependency.aws.outputs.karpenter_interruption_name
      aws_lb_name                 = dependency.aws.outputs.aws_lb_name
    }
  }
}
