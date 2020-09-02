resource "aws_acm_certificate" "cert" {
    domain_name = var.custom_domain
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}

data "cloudflare_zones" "this" {
    filter {
        name = var.cf_zone
        status = "active"
        paused = false
    }
    count = var.use_custom_domain && var.use_cf_for_dns ? 1 : 0
}

resource "cloudflare_record" "cert_validation" {
    #for_each = aws_acm_certificate.cert.domain_validation_options

    zone_id = data.cloudflare_zones.this[0].zones[0].id
    name     = tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_name
    type     = tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_type
    value    = tolist(aws_acm_certificate.cert.domain_validation_options).0.resource_record_value
    ttl      = 3600
    proxied  = false
    count = var.use_custom_domain && var.use_cf_for_dns ? 1 : 0
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [cloudflare_record.cert_validation[0].hostname]
  count = var.use_custom_domain ? 1 : 0

}

resource "aws_api_gateway_domain_name" "apigw_custom_domain" {
    depends_on = [
        aws_acm_certificate_validation.cert
    ]
    certificate_arn = aws_acm_certificate.cert.arn
    domain_name = var.custom_domain
    count = var.use_custom_domain ? 1 : 0
}

resource "cloudflare_record" "cname" {
    zone_id = data.cloudflare_zones.this[0].zones[0].id
    type = "CNAME"
    ttl = 3600 # Must be set to 1 when proxied is true
    proxied = false
    name = var.custom_domain
    value = aws_api_gateway_domain_name.apigw_custom_domain[0].cloudfront_domain_name
    count = var.use_custom_domain && var.use_cf_for_dns ? 1 : 0
}

resource "aws_api_gateway_base_path_mapping" "api_path" {
    api_id = aws_api_gateway_rest_api.screenshot_api.id
    stage_name = aws_api_gateway_stage.prod_stage.stage_name
    domain_name = aws_api_gateway_domain_name.apigw_custom_domain[0].domain_name
    count = var.use_custom_domain ? 1 : 0
}

output "custom_domain_endpoint" {
    value = var.use_custom_domain ? "https://${var.custom_domain}/screenshot" : "N/A"
}