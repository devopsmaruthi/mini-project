locals {
  tags           = merge(var.var_tags, { Name = "mini-proj-${terraform.workspace}" })
  az_name        = data.aws_availability_zones.azs.names
  az_count       = length(local.az_name)
  pub_subnet_ids = aws_subnet.public.*.id
  pri_subnet_ids = aws_subnet.private.*.id
}