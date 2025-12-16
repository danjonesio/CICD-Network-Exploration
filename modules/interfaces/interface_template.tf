resource "iosxe_interface_ethernet" "interface" {
  for_each = var.interfaces

  type              = each.value.interface_type
  device            = each.value.device
  name              = each.value.interface
  description       = each.value.description
  shutdown          = each.value.shutdown
  ipv4_address      = each.value.ip_address
  ipv4_address_mask = each.value.subnet_mask
}