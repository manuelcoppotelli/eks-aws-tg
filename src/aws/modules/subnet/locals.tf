locals {
  snets = {
    for id in var.zone_ids :
    id => cidrsubnet(
      var.vpc_cidr,
      var.newbits,
      var.displacement + index(var.zone_ids, id)
    )
  }
}
