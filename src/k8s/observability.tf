data "kubectl_file_documents" "metric_server" {
  content = file("manifests/observability/metric_server.yaml")
}

resource "kubectl_manifest" "metric_server" {
  for_each  = data.kubectl_file_documents.metric_server.manifests
  yaml_body = each.value
}

data "kubectl_file_documents" "aws_cloudwatch" {
  content = templatefile(
    "manifests/observability/aws_cloudwatch.yaml.tpl",
    {
      region            = var.aws_region
      log_group_name    = format("/aws/eks/%s/pods", data.aws_eks_cluster.control_plane.name)
      log_stream_prefix = "fargate-"
    }
  )
}

resource "kubectl_manifest" "aws_cloudwatch" {
  for_each  = data.kubectl_file_documents.aws_cloudwatch.manifests
  yaml_body = each.value
}
