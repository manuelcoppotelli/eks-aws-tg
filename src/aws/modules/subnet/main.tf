resource "aws_subnet" "this" {
  for_each = local.snets

  vpc_id               = var.vpc_id
  cidr_block           = each.value
  availability_zone_id = each.key

  tags = merge(
    {
      Name = format("%s-%s-%s", var.environment, var.name, each.key)
    },
    var.tags
  )
}

resource "aws_route_table" "this" {
  for_each = local.snets

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = format("%s-%s-%s", var.environment, var.name, each.key)
    },
    var.tags
  )
}

resource "aws_route_table_association" "this" {
  for_each = local.snets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}
