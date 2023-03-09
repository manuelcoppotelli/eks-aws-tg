resource "helm_release" "load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = var.charts.load_balancer.repository
  chart      = "aws-load-balancer-controller"
  version    = var.charts.load_balancer.version

  namespace        = "kube-system"
  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "controllerConfig.featureGates.ServiceTypeLoadBalancerOnly"
    value = "true"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.aws_iam_role.aws_lb.arn
  }
  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.control_plane.name
  }
}
