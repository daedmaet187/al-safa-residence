# Phase 2: Infrastructure Plan

**Status**: PENDING — awaiting Watson + human approval before tofu apply  
**Agent**: Codex (write modules) → Watson runs tofu plan → human approves → Watson runs tofu apply  

---

## Context

Provision AWS infrastructure for Al-Safa Residence on eu-central-1.
Scale tier: Growth (auto-scaling ECS, Multi-AZ RDS).
DNS via Cloudflare (stuff187.com zone).

---

## Files to Read First

1. `PROJECT.md` — full config
2. `ai-project-factory/stacks/infra/aws-ecs-fargate.md` — pattern reference

---

## OpenTofu Modules to Create

```
infra/
├── main.tf              # Root module wiring
├── variables.tf         # Input variables
├── outputs.tf           # ECR URL, ALB DNS, RDS endpoint, CF distribution
├── versions.tf          # Provider version pins
├── terraform.tfvars.example
└── modules/
    ├── networking/      # VPC, subnets, NAT gateway, security groups
    ├── compute/         # ECS cluster, ECR, task definition, ALB
    ├── database/        # RDS PostgreSQL (Multi-AZ for growth tier)
    ├── storage/         # S3 bucket (file uploads), CloudFront distribution
    ├── secrets/         # AWS Secrets Manager secret skeleton
    └── dns/             # Cloudflare DNS records
```

---

## Key Configuration

### Networking
- VPC CIDR: 10.0.0.0/16
- 2 public subnets (ALB): 10.0.1.0/24, 10.0.2.0/24
- 2 private subnets (ECS + RDS): 10.0.10.0/24, 10.0.11.0/24
- NAT gateway: 1 (growth tier)

### Compute (ECS Fargate)
- Cluster: al-safa-residence-production
- Task: 512 CPU / 1024 MB (backend)
- Auto-scaling: min 1, max 4 tasks
- ECR: al-safa-residence-api

### Database (RDS PostgreSQL)
- Engine: PostgreSQL 16
- Instance: db.t3.medium (growth)
- Multi-AZ: true
- DB name: alsafa_production
- Credentials: stored in Secrets Manager

### Storage (S3 + CloudFront)
- S3 bucket: al-safa-residence-uploads-{account_id}
- CloudFront for admin dashboard: safa-admin.stuff187.com
- CloudFront for file delivery

### DNS (Cloudflare)
- `safa-api.stuff187.com` → CNAME to ALB DNS name (proxied: false, for SSL passthrough)
- `safa-admin.stuff187.com` → CNAME to CloudFront distribution (proxied: true)
- `safa.stuff187.com` → CNAME to CloudFront (landing, proxied: true)

### Secrets Manager
Secret path: `/al-safa-residence/production/app`
Keys to pre-create (values filled after deploy):
- DATABASE_URL
- JWT_ACCESS_SECRET
- JWT_REFRESH_SECRET
- FCM_SERVER_KEY
- S3_BUCKET_NAME
- CLOUDFRONT_URL

---

## Provider Versions

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

---

## Acceptance Criteria

- [ ] `tofu validate` passes with no errors
- [ ] `tofu plan` shows expected resources (VPC, subnets, ECS, ECR, RDS, S3, CloudFront, Secrets Manager, DNS)
- [ ] No resources destroyed in plan output
- [ ] terraform.tfvars.example exists (no real secrets)
- [ ] outputs.tf exposes: ecr_url, alb_dns, rds_endpoint, cloudfront_domain, s3_bucket_name

---

## Outputs Required

These will be needed by Phase 3 implementers:
- `ecr_url` — for Docker push in CI
- `alb_dns` — for health check verification
- `rds_endpoint` — for DATABASE_URL construction
- `cloudfront_domain` — for admin deployment
- `s3_bucket_name` — for file upload config

---

## CHECKPOINT

After Codex writes modules:
1. Watson runs: `cd infra && tofu init && tofu validate && tofu plan -out=tfplan.out`
2. Watson posts plan summary to human
3. Human says "apply" → Watson runs `tofu apply tfplan.out`
4. Watson captures outputs and writes plans/infra-initial.results.md

DO NOT apply without human approval.

---

## Commit Message

```
feat(infra): add OpenTofu modules for AWS + Cloudflare infrastructure
```
