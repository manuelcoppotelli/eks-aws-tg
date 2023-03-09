resource "helm_release" "karpenter" {
  name = "karpenter-controller"

  repository = var.charts.karpenter.repository
  chart      = "karpenter"
  version    = var.charts.karpenter.version

  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.aws_iam_role.karpenter_controller.arn
  }
  set {
    name  = "settings.aws.clusterName"
    value = data.aws_eks_cluster.control_plane.name
  }
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = data.aws_iam_instance_profile.karpenter_node.name
  }
  set {
    name  = "settings.aws.interruptionQueueName"
    value = data.aws_sqs_queue.karpenter_interruption.name
  }
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = file("manifests/karpenter/provisioner.yaml")
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = templatefile(
    "manifests/karpenter/node-template.yaml.tpl",
    {
      cluster_name = data.aws_eks_cluster.control_plane.name
    }
  )
}
