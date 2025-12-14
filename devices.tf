locals {
  routers = {
    "P-01" = {
      host = "192.168.2.220"
      role = "primary"
    }
    "P-02" = {
      host = "192.168.2.221"
      role = "primary"
    }
    "DR-01" = {
      host = "192.168.2.222"
      role = "secondary"
    }
    "DR-02" = {
      host = "192.168.2.223"
      role = "secondary"
    }
  }

  # switches = {
  #   "SW-01" = {
  #     host = "192.168.2.230"
  #     role = "access"
  #   }
  # }

  all_devices = merge(local.routers)
}