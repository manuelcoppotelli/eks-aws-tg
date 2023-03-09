# K8s

The k8s stack manages the deployment of both the infrastructure utilities and
the application workloads.

## Infrastructure components

Among the infrastructure components running instide the cluster there are:

* the karpenter controller which provision new EC2 nodes when needed and compact
the number of nodes when possible, achieving cost saving.
* the load balancer controller (which is not used as ingress controller, but as
provisioner for NLB), register the new workers provisioned by karpenter into
the appropriate target groups (notice, without autoscaling group there would not
be a way to do, unless manually)
* the ingress nginx controller, which handles all the incoming traffic from the
NLB and reconciles the `Ingress` resource; allowing to expose multiple services
via the same domain/endpoint.
* the metric server, which collect utilization metrics from both nodes and pods
allowing to use them for Horizontal Pod Autoscaling.
* the configuration for aws cloudwatch logging
* the identity management which allow mapping IAM roles into kubernetes users
or groups.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.9.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.9.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.golang](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ingress_nginx](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.php](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.aws_auth](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.aws_cloudwatch](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_template](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.metric_server](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_acm_certificate.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_eks_cluster.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_instance_profile.karpenter_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_instance_profile) | data source |
| [aws_iam_role.aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.cluster_fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.karpenter_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.karpenter_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_sqs_queue.karpenter_interruption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [kubectl_file_documents.aws_cloudwatch](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |
| [kubectl_file_documents.metric_server](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to create resources. Default Stockholm | `string` | `"eu-north-1"` | no |
| <a name="input_certificate_domain"></a> [certificate\_domain](#input\_certificate\_domain) | The domain for which to emit the certificate | `string` | n/a | yes |
| <a name="input_charts"></a> [charts](#input\_charts) | The helm charts | <pre>map(object({<br>    values     = string<br>    repository = string<br>    version    = string<br>  }))</pre> | n/a | yes |
| <a name="input_dependencies"></a> [dependencies](#input\_dependencies) | The dependenciens to import from other moduels | <pre>object({<br>    aws = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment | `string` | `"test"` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | The cluster idenity | <pre>object({<br>    map_accounts = list(string)<br>    map_roles = list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    }))<br>    map_users = list(object({<br>      userarn  = string<br>      username = string<br>      groups   = list(string)<br>    }))<br>  })</pre> | <pre>{<br>  "map_accounts": [],<br>  "map_roles": [],<br>  "map_users": []<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
