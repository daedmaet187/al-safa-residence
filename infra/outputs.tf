output "ecr_url" {
  value = module.compute.ecr_url
}

output "alb_dns" {
  value = module.compute.alb_dns
}

output "rds_endpoint" {
  value = module.database.rds_endpoint
}

output "cloudfront_domain" {
  value = module.storage.cloudfront_domain
}

output "s3_bucket_name" {
  value = module.storage.s3_bucket_name
}

output "secrets_arn" {
  value = module.secrets.secret_arn
}
