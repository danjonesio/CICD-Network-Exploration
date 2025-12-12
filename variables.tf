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