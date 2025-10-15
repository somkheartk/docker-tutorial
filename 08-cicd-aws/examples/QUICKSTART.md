# Quick Start Guide - Multi-Environment CI/CD

## 🚀 5-Minute Setup

### 1. Prerequisites
```bash
# Install AWS CLI
brew install awscli  # macOS
# or follow: https://aws.amazon.com/cli/

# Configure AWS
aws configure
```

### 2. Run Setup Script
```bash
cd 08-cicd-aws/examples/scripts
./setup.sh
```

This will automatically:
- ✅ Create ECR repositories (dev, uat, prod)
- ✅ Create ECS clusters (dev, uat, prod)
- ✅ Create IAM user for GitHub Actions
- ✅ Create CloudWatch log groups
- ✅ Generate AWS access credentials

### 3. Configure GitHub

**Add Secrets** (Settings > Secrets and variables > Actions):
```
AWS_ACCESS_KEY_ID_DEV
AWS_SECRET_ACCESS_KEY_DEV
AWS_ACCESS_KEY_ID_UAT
AWS_SECRET_ACCESS_KEY_UAT
AWS_ACCESS_KEY_ID_PROD
AWS_SECRET_ACCESS_KEY_PROD
```

**Create Environments** (Settings > Environments):
- `dev` - No protection
- `uat` - Optional reviewers
- `production` - Required reviewers (2+), wait timer (5 min)

### 4. Copy Workflows
```bash
# From examples directory
cp workflows/*.yml ../../.github/workflows/
```

### 5. Deploy!
```bash
# Deploy to DEV
git checkout -b develop
git push origin develop

# Deploy to UAT
git checkout -b uat
git push origin uat

# Deploy to PROD (requires approval)
git checkout main
git push origin main
```

## 📊 Pipeline Overview

```
┌─────────────┐
│   develop   │ ──▶ Auto-deploy to DEV
└─────────────┘     (Fast feedback, debug logs)
       │
       ▼
┌─────────────┐
│  uat/release│ ──▶ Auto-deploy to UAT
└─────────────┘     (Security scan, smoke tests)
       │
       ▼
┌─────────────┐
│    main     │ ──▶ Manual approval ──▶ Deploy to PROD
└─────────────┘     (Blue-green, full tests)
```

## 🎯 Deployment Triggers

| Branch | Environment | Trigger | Approval | Strategy |
|--------|-------------|---------|----------|----------|
| `develop` | DEV | Auto | None | Rolling |
| `uat`, `release/*` | UAT | Auto | Optional | Rolling |
| `main`, `v*.*.*` | PROD | Auto | Required | Blue-Green |

## 📁 File Structure

```
examples/
├── workflows/              # GitHub Actions
│   ├── deploy-dev.yml     # 138 lines
│   ├── deploy-uat.yml     # 173 lines
│   └── deploy-prod.yml    # 242 lines
│
├── task-definitions/       # ECS Task Definitions
│   ├── task-definition-dev.json
│   ├── task-definition-uat.json
│   └── task-definition-prod.json
│
├── scripts/               # Shell Scripts
│   ├── setup.sh          # Automated setup
│   ├── deploy-dev.sh     # Manual deploy to DEV
│   ├── deploy-uat.sh     # Manual deploy to UAT
│   ├── deploy-prod.sh    # Manual deploy to PROD
│   └── rollback-prod.sh  # Rollback PROD
│
├── docker-compose/        # Local Development
│   ├── docker-compose.dev.yml
│   ├── docker-compose.uat.yml
│   └── docker-compose.prod.yml
│
├── .env.dev.example      # Environment variables
├── .env.uat.example
├── .env.prod.example
├── Dockerfile            # Multi-stage build
└── appspec.yaml          # Blue-green config
```

## 🔧 Common Commands

### Deploy Manually
```bash
# DEV
./scripts/deploy-dev.sh v1.0.0-dev

# UAT
./scripts/deploy-uat.sh v1.0.0-rc1

# PROD
./scripts/deploy-prod.sh v1.0.0
```

### Check Status
```bash
# List running tasks
aws ecs list-tasks --cluster myapp-prod-cluster

# View service details
aws ecs describe-services \
  --cluster myapp-prod-cluster \
  --services myapp-prod-service

# View logs
aws logs tail /ecs/myapp-prod --follow
```

### Rollback
```bash
# Interactive (choose from list)
./scripts/rollback-prod.sh

# Specific version
./scripts/rollback-prod.sh arn:aws:ecs:...:task-definition/myapp-prod-task:42
```

## 🐛 Troubleshooting

### Deployment Failed
```bash
# Check service events
aws ecs describe-services \
  --cluster myapp-prod-cluster \
  --services myapp-prod-service \
  --query 'services[0].events[0:5]'

# Check task logs
aws logs tail /ecs/myapp-prod --since 30m
```

### Image Scan Failed
```bash
# View scan results
aws ecr describe-image-scan-findings \
  --repository-name myapp-prod \
  --image-id imageTag=latest

# Fix vulnerabilities
npm audit fix
```

### Service Not Stable
```bash
# Check health
curl http://your-alb-url/health

# Check task definition
aws ecs describe-task-definition \
  --task-definition myapp-prod-task
```

## 📚 Documentation

- [Full Examples Documentation](./README.md)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)

## 💡 Best Practices

1. ✅ **Test in DEV first** - Always test changes in DEV before UAT/PROD
2. ✅ **Use feature branches** - Create feature branches, merge to develop
3. ✅ **Tag releases** - Use semantic versioning for production (v1.0.0)
4. ✅ **Monitor metrics** - Check CloudWatch/Grafana after deployment
5. ✅ **Keep backups** - Automated task definition backups before deploy
6. ✅ **Document changes** - Write clear commit messages and changelogs

## 🔒 Security Checklist

- [ ] AWS credentials stored in GitHub Secrets
- [ ] Sensitive data in AWS Secrets Manager
- [ ] ECR image scanning enabled
- [ ] VPC and security groups configured
- [ ] IAM roles follow least privilege
- [ ] CloudWatch logs enabled
- [ ] Production requires approval
- [ ] Critical vulnerabilities blocked

## 🎉 Next Steps

1. Review [examples/README.md](./README.md) for detailed documentation
2. Customize workflows for your application
3. Set up monitoring and alerting
4. Configure blue-green deployment
5. Implement automated tests
6. Add production smoke tests

---

**Need Help?** Check the [full documentation](./README.md) or [open an issue](https://github.com/somkheartk/docker-tutorial/issues)
