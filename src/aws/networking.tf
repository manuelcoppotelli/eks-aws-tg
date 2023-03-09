data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidrs.vpc
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" : var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" : var.environment
  }
}

module "subnet_data" {
  source = "./modules/subnet"

  name         = "data"
  environment  = var.environment
  zone_ids     = data.aws_availability_zones.available.zone_ids
  vpc_id       = aws_vpc.main.id
  vpc_cidr     = var.cidrs.vpc
  newbits      = var.subnets.data.newbits
  displacement = var.subnets.data.displacement
}

module "subnet_back" {
  source = "./modules/subnet"

  name         = "back"
  environment  = var.environment
  zone_ids     = data.aws_availability_zones.available.zone_ids
  vpc_id       = aws_vpc.main.id
  vpc_cidr     = var.cidrs.vpc
  newbits      = var.subnets.back.newbits
  displacement = var.subnets.back.displacement

  tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.cluster_name
  }
}

module "subnet_front" {
  source = "./modules/subnet"

  name         = "front"
  environment  = var.environment
  zone_ids     = data.aws_availability_zones.available.zone_ids
  vpc_id       = aws_vpc.main.id
  vpc_cidr     = var.cidrs.vpc
  newbits      = var.subnets.front.newbits
  displacement = var.subnets.front.displacement

  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "main" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = module.subnet_front.ids[data.aws_availability_zones.available.zone_ids[0]]
  connectivity_type = "public"

  tags = {
    Name = format("%s", var.environment)
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "back" {
  for_each = module.subnet_back.route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route" "front" {
  for_each = module.subnet_front.route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

output "networking_vpc_id" {
  value = aws_vpc.main.id
}
