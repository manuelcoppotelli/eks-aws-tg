data "aws_iam_policy_document" "karpenter_controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = format("%s:sub", replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""))
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_policy_document" "karpenter_controller_cluster" {
  statement {
    effect = "Allow"
    actions = [
      # Write Operations
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      # Read Operations
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "pricing:GetProducts",
      "ssm:GetParameter",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      # Write Operations
      "sqs:DeleteMessage",
      # Read Operations
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [
      aws_sqs_queue.karpenter_interruption.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.karpenter_node.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = [
      format("arn:%s:eks:%s:%s:cluster/%s", local.aws_partition, var.aws_region, local.aws_account_id, local.cluster_name)
    ]
  }
}

resource "aws_iam_policy" "karpenter_controller_cluster" {
  name_prefix = format("%s-karpenter-controller-", local.cluster_name)
  policy      = data.aws_iam_policy_document.karpenter_controller_cluster.json
}

resource "aws_iam_role" "karpenter_controller" {
  name_prefix        = format("%s-karpenter-controller-", local.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_cluster" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_cluster.arn
}

resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = format("%s-karpenter-interruption", local.cluster_name)
  message_retention_seconds = 300
}

data "aws_iam_policy_document" "karpenter_interruption" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
  }
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy    = data.aws_iam_policy_document.karpenter_interruption.json
}

resource "aws_cloudwatch_event_rule" "aws_health" {
  name        = "aws_health"
  description = "AWS Health Event"

  event_pattern = jsonencode({
    source = [
      "aws.health"
    ]
    detail-type = [
      "AWS Health Event"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_aws_health" {
  rule      = aws_cloudwatch_event_rule.aws_health.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "aws_ec2_spot_int" {
  name        = "aws_ec2_spot_int"
  description = "EC2 Spot Instance Interruption Warning"

  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]
    detail-type = [
      "EC2 Spot Instance Interruption Warning"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_aws_ec2_spot_int" {
  rule      = aws_cloudwatch_event_rule.aws_ec2_spot_int.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "aws_ec2_rebalance" {
  name        = "aws_ec2_rebalance"
  description = "EC2 Instance Rebalance Recommendation"

  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]
    detail-type = [
      "EC2 Instance Rebalance Recommendation"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_aws_ec2_rebalance" {
  rule      = aws_cloudwatch_event_rule.aws_ec2_rebalance.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "aws_ec2_change" {
  name        = "aws_ec2_change"
  description = "EC2 Instance State-change Notification"

  event_pattern = jsonencode({
    source = [
      "aws.ec2"
    ]
    detail-type = [
      "EC2 Instance State-change Notification"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_aws_ec2_change" {
  rule      = aws_cloudwatch_event_rule.aws_ec2_change.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = aws_eks_cluster.control_plane.name
  fargate_profile_name   = format("%s-karpenter", local.cluster_name)
  pod_execution_role_arn = aws_iam_role.cluster_fargate.arn
  subnet_ids             = values(module.subnet_back.ids)

  selector {
    namespace = "karpenter"
  }
}

output "karpenter_controller_name" {
  value = aws_iam_role.karpenter_controller.name
}

output "karpenter_interruption_name" {
  value = aws_sqs_queue.karpenter_interruption.name
}
