apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
%{ if length(accounts) > 0 }
  mapAccounts: |
%{ for account in accounts ~}
      - ${account}
%{ endfor ~}
%{ endif }
%{ if length(roles) > 0 }
  mapRoles: |
%{ for role in roles ~}
    - rolearn: ${role.rolearn}
      username: ${role.username}
      groups:
%{ for group in role.groups ~}
        - ${group}
%{ endfor ~}
%{ endfor ~}
%{ endif }
%{ if length(users) > 0 }
  mapUsers: |
%{ for user in users ~}
    - userarn: ${user.user}
      username: ${user.username}
      groups:
%{ for group in user.groups ~}
        - ${group}
%{ endfor ~}
%{ endfor ~}
%{ endif }
