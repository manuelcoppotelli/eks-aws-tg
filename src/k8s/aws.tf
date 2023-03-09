data "aws_vpc" "main" {
  id = var.dependencies.aws.networking_vpc_id
}

data "aws_eks_cluster" "control_plane" {
  name = var.dependencies.aws.cluster_name
}

data "aws_iam_role" "cluster_fargate" {
  name = var.dependencies.aws.cluster_fargate
}

data "aws_iam_role" "karpenter_controller" {
  name = var.dependencies.aws.karpenter_controller_name
}

data "aws_iam_instance_profile" "karpenter_node" {
  name = var.dependencies.aws.karpenter_node_profile_name
}

data "aws_iam_role" "karpenter_node" {
  name = var.dependencies.aws.karpenter_node_role_name
}

data "aws_sqs_queue" "karpenter_interruption" {
  name = var.dependencies.aws.karpenter_interruption_name
}

data "aws_iam_role" "aws_lb" {
  name = var.dependencies.aws.aws_lb_name
}

data "aws_acm_certificate" "domain" {
  domain      = var.certificate_domain
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  statuses    = ["ISSUED"]
}
