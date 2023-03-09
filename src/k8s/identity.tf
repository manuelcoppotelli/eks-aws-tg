locals {
  map_accounts = concat(var.identity.map_accounts, [])
  map_users    = concat(var.identity.map_users, [])
  map_roles = concat(var.identity.map_roles, [
    {
      groups = [
        "system:bootstrappers",
        "system:nodes",
        "system:node-proxier",
      ]
      rolearn  = data.aws_iam_role.cluster_fargate.arn
      username = "system:node:{{SessionName}}"
    },
    {
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
      username = "system:node:{{EC2PrivateDNSName}}"
      rolearn  = data.aws_iam_role.karpenter_node.arn
    }
  ])
}

resource "kubectl_manifest" "aws_auth" {
  yaml_body = templatefile("manifests/identity/aws_auth.yaml.tpl", {
    users    = local.map_users
    roles    = local.map_roles
    accounts = local.map_accounts
  })
}
