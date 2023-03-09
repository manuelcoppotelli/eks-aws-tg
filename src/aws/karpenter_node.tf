resource "aws_iam_instance_profile" "karpenter_node" {
  name_prefix = format("%s-karpenter-node-", local.cluster_name)
  role        = aws_iam_role.karpenter_node.name
}

data "aws_iam_policy_document" "karpenter_node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [format("ec2.%s", local.aws_url_suffix)]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "karpenter_node" {
  name_prefix        = format("%s-karpenter-node-", local.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.karpenter_node_assume.json
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKS_CNI_Policy", local.aws_partition)
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSWorkerNodePolicy", local.aws_partition)
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", local.aws_partition)
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = format("arn:%s:iam::aws:policy/AmazonSSMManagedInstanceCore", local.aws_partition)
}

resource "aws_security_group" "karpenter_node" {
  name_prefix            = format("%s-karpenter-node-", local.cluster_name)
  description            = "Communication between the control plane and worker nodes"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true

  tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "karpenter_node_in_self" {
  security_group_id = aws_security_group.karpenter_node.id

  description                  = "Allow nodes to communicate with each other"
  referenced_security_group_id = aws_security_group.karpenter_node.id
  ip_protocol                  = -1
  from_port                    = -1
  to_port                      = -1
}

resource "aws_vpc_security_group_egress_rule" "karpenter_node_out_all" {
  security_group_id = aws_security_group.karpenter_node.id

  description = "Allow nodes to communicate with each other"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
  from_port   = -1
  to_port     = -1
}

resource "aws_vpc_security_group_ingress_rule" "karpenter_node_in_cp" {
  security_group_id = aws_security_group.karpenter_node.id

  description                  = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
}

resource "aws_vpc_security_group_egress_rule" "control_plane_out_node" {
  security_group_id = aws_security_group.cluster.id

  description                  = "Allow the cluster control plane to communicate with worker Kubelet and pods"
  referenced_security_group_id = aws_security_group.karpenter_node.id
  ip_protocol                  = "tcp"
  from_port                    = 1025
  to_port                      = 65535
}

resource "aws_vpc_security_group_ingress_rule" "karpenter_node_in_ext" {
  security_group_id = aws_security_group.karpenter_node.id

  description                  = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "control_plane_out_ext" {
  security_group_id = aws_security_group.cluster.id

  description                  = "Allow the cluster control plane to communicate with pods running extension API servers on port 443"
  referenced_security_group_id = aws_security_group.karpenter_node.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "control_plane_in_pod" {
  security_group_id = aws_security_group.cluster.id

  description                  = "Allow pods to communicate with the cluster API Server"
  referenced_security_group_id = aws_security_group.karpenter_node.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

output "karpenter_node_profile_name" {
  value = aws_iam_instance_profile.karpenter_node.name
}

output "karpenter_node_role_name" {
  value = aws_iam_role.karpenter_node.name
}
