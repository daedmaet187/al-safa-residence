module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
}

module "storage" {
  source = "./modules/storage"

  project_name   = var.project_name
  environment    = var.environment
  aws_account_id = var.aws_account_id

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  rds_sg_id          = module.networking.rds_sg_id
  db_password        = var.db_password
}

module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  aws_account_id     = var.aws_account_id
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.networking.alb_sg_id
  ecs_sg_id          = module.networking.ecs_sg_id
  secret_arn         = module.secrets.secret_arn
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "dns" {
  source = "./modules/dns"

  cloudflare_zone_id = var.cloudflare_zone_id
  alb_dns_name       = module.compute.alb_dns
  cloudfront_domain  = module.storage.cloudfront_domain
}
