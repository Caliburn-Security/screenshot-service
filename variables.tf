variable "app_version" {
  type    = string
  default = "0.1"
  description = "Version of this code"
}

variable "region" {
  type    = string
  description = "Which region in AWS to deploy to."
}

variable "s3_screenshot_storage_bucket" {
  type    = string
  description = "The location where the screenshots will be stored"
}

