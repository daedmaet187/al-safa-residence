resource "aws_secretsmanager_secret" "app" {
  name        = "/${var.project_name}/${var.environment}/app"
  description = "Application secrets for ${var.project_name} ${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DATABASE_URL      = "PLACEHOLDER"
    JWT_ACCESS_SECRET = "PLACEHOLDER"
    JWT_REFRESH_SECRET = "PLACEHOLDER"
    FCM_SERVER_KEY    = "PLACEHOLDER"
    S3_BUCKET_NAME    = "PLACEHOLDER"
    CLOUDFRONT_URL    = "PLACEHOLDER"
  })

  lifecycle {
    # Prevent Terraform from overwriting secrets that have been updated externally
    ignore_changes = [secret_string]
  }
}
