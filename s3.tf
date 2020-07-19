resource "aws_s3_bucket" "screenshot_bucket" {
  bucket        = var.s3_screenshot_storage_bucket
  force_destroy = true
  acl = "public-read"

  versioning {
    enabled = false
  }
}