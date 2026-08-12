variable "aws_region" {
  description = "AWS region for the S3 bucket and Route 53 resources"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Domain name for the static site (e.g. example.com). A Route 53 zone will be created for this domain."
  type        = string
}

variable "site_subdomain" {
  description = "Subdomain to serve the site from, e.g. \"www\". Leave empty (\"\") to serve from the apex/root domain (var.domain_name) instead."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository (owner/name) whose Actions workflows may assume the deploy role via OIDC"
  type        = string
  default     = "hbod8/seattle-photo-club-website"
}

variable "index_document" {
  description = "S3 key of the default index document"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "S3 key of the custom error document (served for 404s)"
  type        = string
  default     = "error.html"
}
