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


provider "netbox" {
  server_url = var.netbox_url
  api_token  = var.netbox_token
}

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

module "interfaces" {
  source     = "./modules/interfaces"
  interfaces = local.netbox_interfaces
}

resource "iosxe_save_config" "save_config" {
  for_each = local.all_devices
  device   = each.key

  depends_on = [
    module.snmp,
    module.banner,
    module.interfaces,
  ]
}
