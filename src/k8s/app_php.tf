resource "helm_release" "php" {
  name = "php"

  repository = var.charts.php.repository
  chart      = "php-chart"
  version    = var.charts.php.version

  namespace        = "php"
  create_namespace = true

  values = [
    var.charts.php.values
  ]

  set {
    name  = "environment"
    value = var.environment
  }
}
