variable "username" {
  description = "The username for the network devices"
  type        = string
  sensitive   = true # Marks as sensitive to not expose in the pipeline logs
}

variable "password" {
  description = "The password for the network devices"
  type        = string
  sensitive   = true
}

variable "netbox_url" {
  description = "The URL of the NetBox instance"
  type        = string
  sensitive   = true
}

variable "netbox_token" {
  description = "The API token for accessing NetBox"
  type        = string
  sensitive   = true
}