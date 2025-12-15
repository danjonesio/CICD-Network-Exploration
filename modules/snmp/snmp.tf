resource "iosxe_snmp_server" "snmp_lab" {
  for_each = var.routers

  device = each.key

  contact    = "admin@netcask.com"
  location   = each.value.site
  chassis_id = "Lab-Router-${each.key}"
}