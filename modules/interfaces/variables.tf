variable "interfaces" {
  description = "Map of interfaces to configure (keyed by device:interface_name)"
  type = map(object({
    device         = string
    interface      = string
    name           = string
    description    = string
    ip_address     = optional(string)
    subnet_mask    = optional(string)
    shutdown       = bool
    interface_type = string
  }))
}