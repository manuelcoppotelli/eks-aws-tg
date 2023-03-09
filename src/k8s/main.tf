terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

provider "aws" {}

# Resources creating the cluster SHOULD NOT be created in the same Terraform
# module where Kubernetes provider resources are also used. Otherwise could lead
# to intermittent and unpredictable errors which are hard to debug and diagnose.
# Since can only reference values that are known before the configuration is applied
# <https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs>
# <https://developer.hashicorp.com/terraform/language/providers/configuration>
provider "kubectl" {
  host                   = data.aws_eks_cluster.control_plane.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.control_plane.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.control_plane.name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.control_plane.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.control_plane.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.control_plane.name
      ]
    }
  }
}
