locals {
  cluster_name = format("%s-cluster", var.environment)
}

resource "aws_eks_cluster" "control_plane" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_service.arn

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = var.control_plane.public_access.enabled
    public_access_cidrs     = var.control_plane.public_access.cidrs
    security_group_ids = [
      aws_security_group.cluster.id
    ]
    subnet_ids = values(module.subnet_back.ids)
  }
  enabled_cluster_log_types = var.control_plane.log.types
  version                   = var.control_plane.version

  # Ensure that IAM Role permissions are created before and deleted after EKS
  # Cluster handling. Otherwise, EKS will not be able to properly delete EKS
  # managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_resource_controller,
    aws_cloudwatch_log_group.cluster,
  ]
}

# Not actually fetching, just generate json
data "aws_iam_policy_document" "eks_svc_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_service" {
  description        = local.cluster_name
  assume_role_policy = data.aws_iam_policy_document.eks_svc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSClusterPolicy", local.aws_partition)
  role       = aws_iam_role.eks_service.name
}

# Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks_resource_controller" {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSVPCResourceController", local.aws_partition)
  role       = aws_iam_role.eks_service.name
}

resource "aws_cloudwatch_log_group" "cluster" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = format("/aws/eks/%s/cluster", local.cluster_name)
  retention_in_days = var.control_plane.log.retention
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.control_plane.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.cluster.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.cluster.url
}

resource "aws_security_group" "cluster" {
  name_prefix            = format("%s-", local.cluster_name)
  description            = "Communication between the control plane and worker node groups"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true
}

resource "aws_vpc_security_group_ingress_rule" "cluster_in_self" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = -1
}

resource "aws_vpc_security_group_egress_rule" "cluster_out_all" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

data "aws_iam_policy_document" "cluster_fargate_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cluster_fargate_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_fargate_logging" {
  name_prefix = format("%s-fargate-logging-", local.cluster_name)
  policy      = data.aws_iam_policy_document.cluster_fargate_logging.json
}

resource "aws_iam_role" "cluster_fargate" {
  name_prefix        = format("%s-fargate-", local.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.cluster_fargate_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster_fargate" {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy", local.aws_partition)
  role       = aws_iam_role.cluster_fargate.name
}

resource "aws_iam_role_policy_attachment" "cluster_fargate_logging" {
  policy_arn = aws_iam_policy.cluster_fargate_logging.arn
  role       = aws_iam_role.cluster_fargate.name
}

output "cluster_name" {
  value = aws_eks_cluster.control_plane.name
}

output "cluster_fargate" {
  value = aws_iam_role.cluster_fargate.name
}
