# RDS Users strategy

![rds](assets/rds-user-strategy.png)

The relevant aspect in accessing such resources is keeping track of who has
requested access to what.

## Requesting access

The way of requesting can be simply a private git repo, which is containing
a file for each database and the list of usernames who want to access.

Creating a PR on that repository could trigger a webhook (or a github action)
which execute a temporary job on the AWS account inside the VPC (e.g. github
self hosted runners), which has the permission to create other users.

After creating the user, the job can store the password in the secret manager
tagging it so that only the requester can retrieve that secret.

### Access through IAM

Since each service in AWS (and in EKS) can have an IAM role, application can be
given database access by enabling "IAM database authentication". This way
would prevent any credential to be generated or leaked.

### Credential access

Although the IAM database authentication can be used by the developers as well
to generate connection tokens, it is not the recommended solution when the
workload reaches more that 200 new IAM database authentication connections per
second. In that case handling username/password credentials is recommended.

To allow a user retrieving only the secret they have requestes, SecretManager
offers the possibility to evaluate condition con the policy based on the tags
on the secret itself matching the tag on the IAM user or role

```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {
      "AWS": "123456789012"
    },
    "Condition": {
      "StringEquals": {
        "aws:ResourceTag/AccessProject": "${ aws:PrincipalTag/AccessProject }"
      }
    },
    "Action": "secretsmanager:GetSecretValue",
    "Resource": "*"
  }
}
```

## How can user access a DB in private subnet?

### Port forwarding via a bastion host

It is possible to leverage AWS SessionManager to start a port forwarding session
without having to deal with ssh keys:

```sh
aws ssm start-session --region $AWS_REGION \
    --target $BASTION_ID \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host="$RDS_ENDPOINT",portNumber="5432",localPortNumber="5432"
```

Or create on-the-fly jump hosts based on fargate with resoult as a cheaper
solution (~$0.01/hour) using [7777](https://github.com/whilenull/7777-support)
tool.

### Setting up a Client VPN endpoints to the VPC

Using AWS Client VPN endpoints and attaching it to the VPC

### Setting up a Site-to-Site VPN to the home/office firewall

Using AWS VPN Gateway and attaching it to the VPC or to the Transit Gateway
