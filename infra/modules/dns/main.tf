terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# API: CNAME → ALB (proxied: false — SSL terminates at ALB)
resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "safa-api"
  value   = var.alb_dns_name
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# Admin dashboard: CNAME → CloudFront (proxied: true)
resource "cloudflare_record" "admin" {
  zone_id = var.cloudflare_zone_id
  name    = "safa-admin"
  value   = var.cloudfront_domain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Landing page: CNAME → CloudFront (proxied: true)
resource "cloudflare_record" "landing" {
  zone_id = var.cloudflare_zone_id
  name    = "safa"
  value   = var.cloudfront_domain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
