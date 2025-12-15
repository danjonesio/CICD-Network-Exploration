variable "routers" {
  description = "Map of router devices"
  type = map(object({
    host = string
    site = string
  }))
}