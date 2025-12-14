resource "iosxe_banner" "banner_lab" {
  for_each = var.routers

  device = each.key

  login_banner = "** This is a lab device managed by Terraform. Unauthorized access is prohibited. **"
  delete_mode  = "all"
}