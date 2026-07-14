locals {
  # site_fqdn is the original resource-naming string ("www.<domain>") that
  # the already-provisioned S3 bucket and IAM policy are named after. Kept
  # unchanged so those resources aren't renamed/replaced; it no longer
  # indicates which domain is actually served as primary.
  site_fqdn = var.site_subdomain == "" ? var.domain_name : "${var.site_subdomain}.${var.domain_name}"

  # Domain served as the canonical site (apex) vs. the one that 301s to it.
  primary_fqdn  = var.domain_name
  redirect_fqdn = "www.${var.domain_name}"
}
