# Phase 6 — CI/CD Results

**Date**: 2026-04-29  
**Status**: Workflows written and running

---

## Workflows written

### `.github/workflows/backend.yml`
- **Trigger**: push to `main` affecting `backend/**` or the workflow file itself
- **Jobs**:
  - `test`: Node 20, `npm ci`, `npm test`
  - `build-and-deploy` (needs: test):
    - Builds Docker image tagged with `$GITHUB_SHA` and `latest`
    - Pushes both tags to ECR `590184057237.dkr.ecr.eu-central-1.amazonaws.com/al-safa-residence-api`
    - Registers a one-off `al-safa-residence-production-migrate` ECS task definition with `npx prisma migrate deploy` command; DATABASE_URL from Secrets Manager
    - Runs migration task on Fargate, waits for completion, asserts exit code 0
    - Downloads current task definition, renders new revision with updated image
    - Creates ECS service `al-safa-residence-production-api` if not exists (with ALB target group `alsafa-prod-api-tg`)
    - Deploys and waits for service stability

### `.github/workflows/admin.yml`
- **Trigger**: push to `main` affecting `admin/**` or the workflow file itself
- **Jobs**:
  - `build-and-deploy`: Node 20, `npm ci && npm run build`, sync `admin/dist/` → S3 `al-safa-residence-admin-590184057237`, dynamically looks up CloudFront distribution for `safa-admin.stuff187.com` and invalidates `/*` (skips gracefully if distribution not yet provisioned)

### `.github/workflows/mobile.yml`
- **Trigger**: push to `main` affecting `mobile/**` or the workflow file itself
- **Jobs**:
  - `test`: Flutter 3.24.5, `flutter pub get`, `flutter analyze`, `flutter test`
  - `build-apk` (needs: test): Flutter 3.24.5, `flutter build apk --release`, uploads `app-release.apk` as GitHub Actions artifact (30-day retention)

---

## Infrastructure values used

| Resource | Value |
|---|---|
| ECR | `590184057237.dkr.ecr.eu-central-1.amazonaws.com/al-safa-residence-api` |
| ECS cluster | `al-safa-residence-production` |
| ECS service | `al-safa-residence-production-api` |
| Task execution role | `arn:aws:iam::590184057237:role/al-safa-residence-production-ecs-task-execution` |
| Private subnets | `subnet-080f6051dc09d7b0a`, `subnet-061e38c5ff878c18a` |
| ECS security group | `sg-09b4736e7f7285c41` |
| Secrets ARN | `arn:aws:secretsmanager:eu-central-1:590184057237:secret:/al-safa-residence/production/app-3giW8l` |
| ALB target group | `arn:aws:elasticloadbalancing:eu-central-1:590184057237:targetgroup/alsafa-prod-api-tg/5ec00e8b16828719` |
| S3 admin bucket | `al-safa-residence-admin-590184057237` |
| CloudFront dist | Not yet provisioned — dynamic lookup in workflow |

---

## Deployment run

- Commit: `8653f61` pushed to `main` at 2026-04-29T14:26:16Z
- All three workflows triggered automatically by the push
- Backend CI/CD: **in_progress** (run `25114746362`)
- Mobile CI/CD: **in_progress** (run `25114746337`)
- Admin Dashboard CI/CD: **queued** (run `25114746287`)
