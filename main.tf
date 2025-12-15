terraform {
  required_providers {
    iosxe = {
      source  = "CiscoDevNet/iosxe"
      version = "0.13.0"
    }
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# NetBox Provider - Source of Truth for device and interface data
# -----------------------------------------------------------------------------
provider "netbox" {
  server_url = var.netbox_url
  api_token  = var.netbox_token
}

# -----------------------------------------------------------------------------
# IOS-XE Provider - Configures Cisco devices via NETCONF
# -----------------------------------------------------------------------------
provider "iosxe" {
  username = var.username
  password = var.password

  devices = [
    for name, device in local.all_devices : {
      name        = name
      host        = device.host
      protocol    = "netconf"
      insecure    = true
      auto_commit = true
    }
  ]
}

module "snmp" {
  source  = "./modules/snmp"
  routers = local.routers
}

module "banner" {
  source  = "./modules/banner"
  routers = local.routers
}

module "wan_interfaces" {
  source         = "./modules/interfaces_core_wan"
  wan_interfaces = local.wan_interfaces
}

resource "iosxe_save_config" "save_config" {
  for_each = local.all_devices
  device   = each.key

  depends_on = [
    module.snmp,
    module.banner,
    module.wan_interfaces,
  ]
}
