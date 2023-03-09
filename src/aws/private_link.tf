resource "aws_security_group" "private_link" {
  name_prefix            = format("%s-private-link-", var.environment)
  description            = "Communication to/from the private links"
  vpc_id                 = aws_vpc.main.id
  revoke_rules_on_delete = true
}

resource "aws_vpc_security_group_ingress_rule" "private_link_in_back" {
  for_each = module.subnet_back.cidr_blocks

  security_group_id = aws_security_group.private_link.id
  description       = "Allow backend communication via private links"
  cidr_ipv4         = each.value
  ip_protocol       = -1
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "private_link_in_data" {
  for_each = module.subnet_data.cidr_blocks

  security_group_id = aws_security_group.private_link.id
  description       = "Allow data communication via private links"
  cidr_ipv4         = each.value
  ip_protocol       = -1
  from_port         = -1
  to_port           = -1
}

data "aws_iam_policy_document" "private_link_ecr" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["ecr:*"]

    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.main.id
  service_name      = format("com.amazonaws.%s.ecr.dkr", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = values(module.subnet_data.ids)
  security_group_ids = [
    aws_security_group.private_link.id,
  ]
  policy              = data.aws_iam_policy_document.private_link_ecr.json
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.main.id
  service_name      = format("com.amazonaws.%s.ecr.api", var.aws_region)
  vpc_endpoint_type = "Interface"

  subnet_ids = values(module.subnet_data.ids)
  security_group_ids = [
    aws_security_group.private_link.id,
  ]
  policy              = data.aws_iam_policy_document.private_link_ecr.json
  private_dns_enabled = true
}

data "aws_iam_policy_document" "private_link_ecr_s3" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = format("com.amazonaws.%s.s3", var.aws_region)
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    values(module.subnet_back.route_table_ids),
    values(module.subnet_data.route_table_ids),
  )

  policy = data.aws_iam_policy_document.private_link_ecr_s3.json
}
