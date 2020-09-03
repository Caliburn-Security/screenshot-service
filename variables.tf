variable "app_version" {
  type    = string
  default = "0.1"
  description = "Version of this code"
}

variable "default_aws_region" {
  type    = string
  description = "Which region in AWS to deploy to."
}

variable "s3_screenshot_storage_bucket" {
  type    = string
  description = "The location where the screenshots will be stored"
}

variable "custom_domain" {
  type = string
  default = null
  description = "Custom domain for use in API Gateway"
}

variable "cf_zone" {
  type = string
  default = null
  description = "The Cloudflare zone for use in deploying the serivce"
}

variable "use_custom_domain" {
  type = bool
  default = false
  description = "Determine if a custom domain will be used"
}

variable "https_default" {
  type = bool
  default = true
  description = "Use https instead of http if no scheme is provided"
}

variable "use_cf_for_dns" {
  type = bool
  default = false
  description = "Use Cloudflare when validating the certificate when using a custom domain"
}

variable "dns_resolver_timeout" {
  type = number
  default = 1
  description = "Set the DNS resolver timeout in seconds"
}

variable "dns_resolver_lifetime" {
  type = number
  default = 1
  description = "Set the DNS query lifetime in seconds"
}

variable "dns_record_types" {
  type = list(string)
  default = ["MX", "AAAA", "A", "NS", "SOA", "CNAME", "TXT"]
  description = "Default DNS record types to check"
}