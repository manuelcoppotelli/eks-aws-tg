# EKS Infrastructure with Terraform

The solution consist of two so-called "_stack_": the first in charge of
provisioning AWS resources the other in charge of deploying resources into
the kubernetes cluster(s).

Terraform files are into the `src` directory, with a subdirectory for each stack.

## Requirements

### Terraform

In order to mange the suitable version of terraform and terragrunt it is
strongly recommended to install the following tools:

* [tfenv](https://github.com/tfutils/tfenv): **Terraform** version manager inspired by rbenv.
* [tgenv](https://github.com/cunymatthieu/tgenv): **Terragrunt** version manager inspired by tfenv.

Once these tools have been installed, install the terraform version and
terragrunt version shown in:

* `.terraform-version`
* `.terragrunt-version`

Then install terraform and terragrunt by typing the command:

```sh
tfenv install
tgenv install
```

### AWS CLI

In order for the terraform provider to work, it is required to install the
[AWS CLI](https://aws.amazon.com/it/cli/).

Once installed, is necessary to authenticate the CLI against the AWS account.

#### Authenticate via AWS IAM Identity Center

In case you use AWS IAM Identity Center (successor to AWS Single Sign-On) to
consolidate the login towards multiple account, run the command:

```sh
aws configure sso
```

If the CLI can open your default browser, it will do so and load an AWS sign-in
page. Otherwise, open a browser page at
<https://device.sso.eu-south-1.amazonaws.com/> and enter the authorization code
displayed in your terminal.

#### Authenticate via AWS IAM

You can authenticate to a single AWS account by defining a profile pointing at
it via the command:

```sh
aws configure --profile <profile-name>
```

## Bootstrapping environments

The aim of the bootstrapping phase is to create the cloud resources necessary to
share the terraform state of the infrastructure among the different developers.

For each region, a new sub-directory will be created under the `env` path;
which contains a sub-directory for each environment and inside that a
sub-directory for each stack/module.

```txt
.
|____env
| |____eu-north-1
| | |____prod
| | | |____aws
| | | | |____terragrunt.hcl
| | | |____k8s
| | |____test
| | | |____aws
| | | |____k8s
| | | | |____terragrunt.hcl
```

The sub-directories of the `env` contain `terragrunt.hcl` files; which are aimed
at defining the terraform variables specific for each environment.

After having defined the variables, the bootstrapping happens by changing
directory to the specific environment and then executing the command.

```sh
cd env/eu-north-1/prod/aws

AWS_PROFILE=devops terragrunt init
```

The `init` command will take care of creating the necessary S3 bucket and
DynamoDB table used as backend for the terraform state.

## Infrastructure deploy

The infrastructure as code can be deployed by changing directory into the chosen
region, environment, stack and then typing the commands:

```sh
cd env/eu-north-1/prod/aws

AWS_PROFILE=devops terragrunt plan

AWS_PROFILE=devops terragrunt apply
```
