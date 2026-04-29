output "api_record_id" {
  description = "Cloudflare record ID for safa-api.stuff187.com"
  value       = cloudflare_record.api.id
}

output "admin_record_id" {
  description = "Cloudflare record ID for safa-admin.stuff187.com"
  value       = cloudflare_record.admin.id
}

output "landing_record_id" {
  description = "Cloudflare record ID for safa.stuff187.com"
  value       = cloudflare_record.landing.id
}
