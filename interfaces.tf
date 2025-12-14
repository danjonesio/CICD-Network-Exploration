locals {
  # WAN interfaces for routers
  wan_interfaces = {
    "P-01" = {
      interface      = "1"
      description    = "WAN Uplink - Primary"
      ip_address     = "10.10.10.1"
      subnet_mask    = "255.255.255.0"
      mtu            = 1500
      bandwidth      = 1000000
      shutdown       = false
      interface_type = "GigabitEthernet"
    }
    "P-02" = {
      interface      = "1"
      description    = "WAN Uplink - Primary"
      ip_address     = "10.10.10.2"
      subnet_mask    = "255.255.255.0"
      mtu            = 1500
      bandwidth      = 1000000
      shutdown       = false
      interface_type = "GigabitEthernet"
    }
    "DR-01" = {
      interface      = "1"
      description    = "WAN Uplink - Secondary"
      ip_address     = "10.10.20.1"
      subnet_mask    = "255.255.255.0"
      mtu            = 1500
      bandwidth      = 1000000
      shutdown       = false
      interface_type = "GigabitEthernet"
    }
    "DR-02" = {
      interface      = "1"
      description    = "WAN Uplink - Secondary"
      ip_address     = "10.10.20.2"
      subnet_mask    = "255.255.255.0"
      mtu            = 1500
      bandwidth      = 1000000
      shutdown       = false
      interface_type = "GigabitEthernet"
    }
  }
}