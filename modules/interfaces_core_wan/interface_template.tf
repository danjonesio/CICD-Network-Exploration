resource "iosxe_interface_ethernet" "wan_int" {
  for_each = var.wan_interfaces

  type              = each.value.interface_type
  device            = each.key
  name              = each.value.interface
  description       = each.value.description
  ipv4_address      = each.value.ip_address
  ipv4_address_mask = each.value.subnet_mask
  shutdown          = each.value.shutdown
}