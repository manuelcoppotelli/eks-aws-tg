apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    karpenter.sh/discovery: ${cluster_name}
  securityGroupSelector:
    karpenter.sh/discovery: ${cluster_name}
