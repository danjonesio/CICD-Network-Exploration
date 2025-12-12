terraform {
  required_providers {
    iosxe = {
      source  = "CiscoDevNet/iosxe"
      version = "0.13.0"
    }
  }
}

provider "iosxe" {
  username = var.username
  password = var.password

  devices = [
    for name, device in local.routers : {
      name        = name
      host        = device.host
      protocol    = "netconf"
      insecure    = true
      auto_commit = true
    }
  ]
}

module "snmp_config" {
  source = "./config"

  routers = local.routers
}

resource "iosxe_save_config" "save_config" {
  for_each = local.routers

  device = each.key

  depends_on = [
    module.snmp_config
  ]
}
