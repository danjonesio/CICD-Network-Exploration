# -----------------------------------------------------------------------------
# NetBox Data Sources
# Fetches device and interface data from NetBox as the source of truth
# -----------------------------------------------------------------------------

# First, get the device role ID for "router"
data "netbox_device_role" "router" {
  name = "Router"
}

# Fetch all devices with the "router" role from NetBox
# These will be used to build local.routers dynamically
data "netbox_devices" "routers" {
  filter {
    name  = "role_id"
    value = data.netbox_device_role.router.id
  }
}

# Fetch all device interfaces - we'll filter by description in locals
# The provider doesn't support description filtering, so we get all and filter
data "netbox_device_interfaces" "all" {
  # Get all interfaces, we'll filter for WAN in locals
}

# Fetch IP addresses for each device
# We filter by device_id to get IPs assigned to each device's interfaces
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

# Fetch sites for each device to get site names
data "netbox_site" "device_sites" {
  for_each = {
    for device in data.netbox_devices.routers.devices :
    device.name => device.site_id
    if device.site_id != null
  }

  id = tostring(each.value)
}

# -----------------------------------------------------------------------------
# Locals - Transform NetBox data into the format expected by modules
# -----------------------------------------------------------------------------
locals {
  # Build a lookup map of device ID -> device name for easy reference
  device_id_to_name = {
    for device in data.netbox_devices.routers.devices :
    device.device_id => device.name
  }

  # Build routers map from NetBox devices
  # Format: { "P-01" = { host = "192.168.2.220", site = "Primary Site" } }
  netbox_routers = {
    for device in data.netbox_devices.routers.devices :
    device.name => {
      host = device.primary_ipv4
      # Get site name from NetBox
      site = try(data.netbox_site.device_sites[device.name].name, "Unknown Site")
    }
    if device.primary_ipv4 != null
  }

  # Filter interfaces that have "WAN" in description and belong to our routers
  wan_interfaces_raw = [
    for iface in data.netbox_device_interfaces.all.interfaces :
    iface
    if iface.description != null && can(regex("(?i)wan", iface.description)) && contains(keys(local.device_id_to_name), tostring(iface.device_id))
  ]

  # Build a lookup of device_name -> WAN IP info from NetBox
  # Filter for IPs with "WAN" in their description
  device_wan_ips = {
    for device_name, ip_data in data.netbox_ip_addresses.device_ips :
    device_name => [
      for ip in ip_data.ip_addresses :
      ip.ip_address # Keep full CIDR notation (e.g., "10.10.10.1/24")
      if ip.description != null && can(regex("(?i)wan", ip.description))
    ]
  }

  # Build WAN interfaces map from NetBox data
  # This transforms NetBox interface + IP data into the format expected by the module
  netbox_wan_interfaces = {
    for iface in local.wan_interfaces_raw :
    lookup(local.device_id_to_name, tostring(iface.device_id), "unknown") => {
      # Parse interface number from name (e.g., "GigabitEthernet 1" -> "1")
      interface   = regex("[0-9]+$", iface.name)
      description = coalesce(iface.description, "WAN Interface")
      # Get the WAN IP for this device - use built-in Terraform functions for CIDR parsing
      ip_address     = try(split("/", local.device_wan_ips[lookup(local.device_id_to_name, tostring(iface.device_id), "unknown")][0])[0], "")
      subnet_mask    = try(cidrnetmask(local.device_wan_ips[lookup(local.device_id_to_name, tostring(iface.device_id), "unknown")][0]), "255.255.255.0")
      shutdown       = !iface.enabled
      interface_type = "GigabitEthernet"
    }
  }
}
