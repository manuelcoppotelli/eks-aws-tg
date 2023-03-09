# App containerization

This process can be automatized via CI/CD pipelines (e.g. via CodeBuild), however
the choise is to describe as it is, with manual commands.

Moreover, to properly deploy the application onto the just created Kubernetes
cluster, the preferred choice was writing helm chart and letting terraform
deploy them.

## Requirements

The solution uses AWS ECR as OCI-compliant registry to store both container
images and helm charss; the registry repositories apre provisioned via terraform
into the `aws` stack.

In addition are required:

- [docker](https://www.docker.com)
- [helm](https://helm.sh)

### Login to the container registry

```sh
AWS_PROFILE=devops aws ecr get-login-password \
    --region $AWS_REGION | docker login \
    --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

### Login to the OCI registry

```sh
AWS_PROFILE=devops aws ecr get-login-password \
    --region $AWS_REGION | helm registry login \
    --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

## Applications

The goal was to containerize the application without editing the source code.
At the same time the effort was on following the 12factors for cloud native apps.

### golang

Application in runtime needs p12 file(filename: file.p12) next to application binary.

```sh
docker build golang/ -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/golang:0.1.0
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/golang:0.1.0
```

```sh
helm package golang/chart
helm push golang-0.1.0.tgz oci://$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
```

I would define the PORT and environment variable. Having port 80 on containerd
may lead to issues <https://github.com/kubernetes/kubernetes/issues/56374>.

### php

Application to run on production needs env `APP_ENV=prod` and file `config` next
to index.php, repository contains `config.prod` and `config.dev`, for production
purposes `config.prod` needs to be renamed to `config`.

```sh
docker build php/ -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/php:0.1.0
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/php:0.1.0
```

```sh
helm package php/chart
helm push php-0.1.0.tgz oci://$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/
```

It is considered a best practice not to include configuration files in docker
images. The respective contet has been defined as configmap and mounted via
kubernetes.

A different decision couls have been including in the container only `php-fpm`
and use the nginx ingress with FCGI backend protocol
<https://kubernetes.github.io/ingress-nginx/user-guide/fcgi-services/>.
However this sets a tradeoff on self-contained docker images and possibility to
switch the ingress controller transparently.
