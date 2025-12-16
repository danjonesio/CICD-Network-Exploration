# Device inventory is sourced from NetBox - see netbox.tf
locals {
  routers     = local.netbox_routers
  all_devices = local.routers
}