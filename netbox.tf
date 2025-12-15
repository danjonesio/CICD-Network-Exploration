# Pull device and interface info from NetBox

# Get the router role so we can filter devices by it
data "netbox_device_role" "router" {
  name = "Router"
}

# All our routers from NetBox
data "netbox_devices" "routers" {
  filter {
    name  = "role_id"
    value = data.netbox_device_role.router.id
  }
}

# All interfaces - we filter for WAN stuff in locals below
data "netbox_device_interfaces" "all" {}

# IPs assigned to each device
data "netbox_ip_addresses" "device_ips" {
  for_each = {
    for device in data.netbox_devices.routers.devices :
    device.name => device.device_id
  }

  filter {
    name  = "device_id"
    value = tostring(each.value)
  }
}

# Site info for each device (used in SNMP location)
data "netbox_site" "device_sites" {
  for_each = {
    for device in data.netbox_devices.routers.devices :
    device.name => device.site_id
    if device.site_id != null
  }

  id = tostring(each.value)
}

# Transform NetBox data into what our modules expect
locals {
  # Quick lookup: device ID -> name
  device_id_to_name = {
    for device in data.netbox_devices.routers.devices :
    device.device_id => device.name
  }

  # Router map: { "P-01" = { host = "192.168.2.220", site = "Primary Site" } }
  netbox_routers = {
    for device in data.netbox_devices.routers.devices :
    device.name => {
      host = device.primary_ipv4
      site = try(data.netbox_site.device_sites[device.name].name, "Unknown Site")
    }
    if device.primary_ipv4 != null
  }

  # Only interfaces with "WAN" in the description
  wan_interfaces_raw = [
    for iface in data.netbox_device_interfaces.all.interfaces :
    iface
    if iface.description != null && can(regex("(?i)wan", iface.description)) && contains(keys(local.device_id_to_name), tostring(iface.device_id))
  ]

  # WAN IPs per device (keeps CIDR notation like "10.10.10.1/24")
  device_wan_ips = {
    for device_name, ip_data in data.netbox_ip_addresses.device_ips :
    device_name => [
      for ip in ip_data.ip_addresses :
      ip.ip_address
      if ip.description != null && can(regex("(?i)wan", ip.description))
    ]
  }

  # WAN interfaces in the format our modules expect
  netbox_wan_interfaces = {
    for iface in local.wan_interfaces_raw :
    lookup(local.device_id_to_name, tostring(iface.device_id), "unknown") => {
      interface      = regex("[0-9]+$", iface.name) # e.g. "GigabitEthernet 1" -> "1"
      description    = coalesce(iface.description, "WAN Interface")
      ip_address     = try(split("/", local.device_wan_ips[lookup(local.device_id_to_name, tostring(iface.device_id), "unknown")][0])[0], "")
      subnet_mask    = try(cidrnetmask(local.device_wan_ips[lookup(local.device_id_to_name, tostring(iface.device_id), "unknown")][0]), "255.255.255.0")
      shutdown       = !iface.enabled
      interface_type = "GigabitEthernet"
    }
  }
}
