variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for stuff187.com"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  type        = string
}
