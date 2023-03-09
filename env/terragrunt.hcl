locals {
  # Parse the file path to retrieve region and environment
  parsed = regex(".*/env/(?P<region>.*?)/(?P<environment>.*?)/(?P<stack>.*?)$", get_terragrunt_dir())

  environment = local.parsed.environment
  aws_region  = local.parsed.region
  stack       = local.parsed.stack
}

inputs = {
  environment = local.environment
  aws_region  = local.aws_region
}

remote_state {
  backend = "s3"
  config = {
    bucket         = format("docplan-tf-backend-%s-%s", local.aws_region, local.environment)
    key            = format("%s/tfstate", local.stack)
    region         = local.aws_region
    dynamodb_table = format("docplan-tf-lock-%s-%s", local.aws_region, local.environment)
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
