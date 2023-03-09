output "ids" {
  value = {
    for k, v in aws_subnet.this : k => v.id
  }
}

output "route_table_ids" {
  value = {
    for k, v in aws_route_table.this : k => v.id
  }
}

output "cidr_blocks" {
  value = local.snets
}
