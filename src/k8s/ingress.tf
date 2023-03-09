resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository = var.charts.ingress.repository
  chart      = "ingress-nginx"
  version    = var.charts.ingress.version

  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    var.charts.ingress.values
  ]

  set {
    name  = "controller.config.proxy-real-ip-cidr"
    value = data.aws_vpc.main.cidr_block_associations[0].cidr_block
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = data.aws_acm_certificate.domain.arn
  }
}
