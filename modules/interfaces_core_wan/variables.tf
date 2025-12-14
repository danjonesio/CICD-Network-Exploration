variable "wan_interfaces" {
  description = "Map of WAN interfaces to be configured on core routers"
  type = map(object({
    interface      = string
    description    = string
    ip_address     = string
    subnet_mask    = string
    mtu            = number
    bandwidth      = number
    shutdown       = bool
    interface_type = string
  }))
}