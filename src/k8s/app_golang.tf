resource "helm_release" "golang" {
  name = "golang"

  repository = var.charts.golang.repository
  chart      = "golang-chart"
  version    = var.charts.golang.version

  namespace        = "golang"
  create_namespace = true

  values = [
    var.charts.golang.values
  ]
}
