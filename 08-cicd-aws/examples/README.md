# ตัวอย่าง CI/CD Pipeline สำหรับ Multi-Environment Deployment

## 📋 สารบัญ

- [ภาพรวม](#ภาพรวม)
- [โครงสร้างไฟล์](#โครงสร้างไฟล์)
- [Environments](#environments)
- [การตั้งค่า GitHub Actions](#การตั้งค่า-github-actions)
- [การใช้งาน Deployment Scripts](#การใช้งาน-deployment-scripts)
- [Docker Compose สำหรับแต่ละ Environment](#docker-compose-สำหรับแต่ละ-environment)
- [Best Practices](#best-practices)

## ภาพรวม

ตัวอย่างนี้แสดงการสร้าง CI/CD Pipeline ที่สมบูรณ์สำหรับ 3 environments:
- **DEV** - Development environment สำหรับทดสอบและพัฒนา
- **UAT** - User Acceptance Testing สำหรับทดสอบก่อน production
- **PROD** - Production environment สำหรับ users จริง

## โครงสร้างไฟล์

```
examples/
├── workflows/              # GitHub Actions workflows
│   ├── deploy-dev.yml     # Deploy to DEV
│   ├── deploy-uat.yml     # Deploy to UAT
│   └── deploy-prod.yml    # Deploy to PROD (with blue-green)
├── task-definitions/       # ECS Task Definitions
│   ├── task-definition-dev.json
│   ├── task-definition-uat.json
│   └── task-definition-prod.json
├── scripts/               # Deployment scripts
│   ├── deploy-dev.sh
│   ├── deploy-uat.sh
│   ├── deploy-prod.sh
│   └── rollback-prod.sh
└── docker-compose/        # Docker Compose files
    ├── docker-compose.dev.yml
    ├── docker-compose.uat.yml
    └── docker-compose.prod.yml
```

## Environments

### 1. DEV Environment
**จุดประสงค์**: Development และ rapid testing

**คุณสมบัติ**:
- Auto-deploy เมื่อ push ไป `develop` branch
- Resource ขนาดเล็ก (256 CPU, 512 MB RAM)
- Log level: DEBUG
- Hot reload support
- Test database และ mail catcher

**การ trigger**:
```bash
git push origin develop
```

### 2. UAT Environment
**จุดประสงค์**: User Acceptance Testing

**คุณสมบัติ**:
- Auto-deploy เมื่อ push ไป `uat` หรือ `release/*` branch
- Resource ขนาดกลาง (512 CPU, 1024 MB RAM)
- Security scanning
- Integration tests
- Smoke tests หลัง deployment

**การ trigger**:
```bash
git push origin uat
# หรือ
git push origin release/v1.0.0
```

### 3. PROD Environment
**จุดประสงค์**: Production สำหรับ users จริง

**คุณสมบัติ**:
- Deploy เมื่อ push ไป `main` หรือ create tag
- Resource ขนาดใหญ่ (1024 CPU, 2048 MB RAM)
- Blue-green deployment
- Comprehensive security scanning
- Critical vulnerability blocking
- Manual approval required
- Auto rollback on failure
- Monitoring และ alerting

**การ trigger**:
```bash
git push origin main
# หรือ
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## การตั้งค่า GitHub Actions

### 1. สร้าง ECR Repositories

```bash
# DEV
aws ecr create-repository \
    --repository-name myapp-dev \
    --image-scanning-configuration scanOnPush=true

# UAT
aws ecr create-repository \
    --repository-name myapp-uat \
    --image-scanning-configuration scanOnPush=true

# PROD
aws ecr create-repository \
    --repository-name myapp-prod \
    --image-scanning-configuration scanOnPush=true
```

### 2. สร้าง ECS Clusters

```bash
# DEV
aws ecs create-cluster --cluster-name myapp-dev-cluster

# UAT
aws ecs create-cluster --cluster-name myapp-uat-cluster

# PROD
aws ecs create-cluster --cluster-name myapp-prod-cluster
```

### 3. ตั้งค่า GitHub Secrets

ไปที่ **Settings > Secrets and variables > Actions** และเพิ่ม:

#### DEV Secrets
- `AWS_ACCESS_KEY_ID_DEV`
- `AWS_SECRET_ACCESS_KEY_DEV`

#### UAT Secrets
- `AWS_ACCESS_KEY_ID_UAT`
- `AWS_SECRET_ACCESS_KEY_UAT`

#### PROD Secrets
- `AWS_ACCESS_KEY_ID_PROD`
- `AWS_SECRET_ACCESS_KEY_PROD`

### 4. ตั้งค่า GitHub Environments

ไปที่ **Settings > Environments** และสร้าง:

#### dev environment
- ไม่ต้องมี protection rules
- URL: `https://dev.myapp.example.com`

#### uat environment
- Required reviewers: 1-2 คน (optional)
- URL: `https://uat.myapp.example.com`

#### production environment
- **Required reviewers**: 2-3 คน
- **Wait timer**: 5 นาที
- URL: `https://myapp.example.com`

### 5. คัดลอก Workflow Files

```bash
# คัดลอก workflows ไปยัง .github/workflows/
mkdir -p .github/workflows
cp examples/workflows/deploy-dev.yml .github/workflows/
cp examples/workflows/deploy-uat.yml .github/workflows/
cp examples/workflows/deploy-prod.yml .github/workflows/
```

## การใช้งาน Deployment Scripts

### Deploy to DEV

```bash
cd 08-cicd-aws/examples/scripts
./deploy-dev.sh v1.0.0-dev
```

### Deploy to UAT

```bash
cd 08-cicd-aws/examples/scripts
./deploy-uat.sh v1.0.0-rc1
```

### Deploy to PROD

```bash
cd 08-cicd-aws/examples/scripts
./deploy-prod.sh v1.0.0
```

### Rollback PROD

```bash
cd 08-cicd-aws/examples/scripts

# แบบอัตโนมัติ (เลือกจาก list)
./rollback-prod.sh

# หรือระบุ task definition เฉพาะ
./rollback-prod.sh arn:aws:ecs:us-east-1:123456789012:task-definition/myapp-prod-task:42
```

## Docker Compose สำหรับแต่ละ Environment

### Local Development (DEV)

```bash
cd 08-cicd-aws/examples/docker-compose
docker-compose -f docker-compose.dev.yml up -d

# ดู logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop
docker-compose -f docker-compose.dev.yml down
```

**Services**:
- App: `http://localhost:3000`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`
- MailHog UI: `http://localhost:8025`

### UAT Environment

```bash
cd 08-cicd-aws/examples/docker-compose
docker-compose -f docker-compose.uat.yml up -d

# ดู logs
docker-compose -f docker-compose.uat.yml logs -f

# Stop
docker-compose -f docker-compose.uat.yml down
```

**Services**:
- App: `http://localhost:3000`
- PostgreSQL: `localhost:5433`
- Redis: `localhost:6380`
- Nginx: `http://localhost`

### Production Environment

```bash
cd 08-cicd-aws/examples/docker-compose

# สร้าง .env.prod file ก่อน
cat > .env.prod << EOF
POSTGRES_PASSWORD=your-strong-password
REDIS_PASSWORD=your-redis-password
GRAFANA_PASSWORD=your-grafana-password
EOF

docker-compose -f docker-compose.prod.yml up -d

# ดู logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop
docker-compose -f docker-compose.prod.yml down
```

**Services**:
- App (2 replicas): `http://localhost:3000`
- PostgreSQL: `localhost:5434`
- Redis: `localhost:6381`
- Nginx: `http://localhost`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

## Best Practices

### 1. Environment Configuration

✅ **ใช้ environment-specific configuration**
```yaml
# dev: DEBUG logs, minimal resources
# uat: INFO logs, moderate resources
# prod: WARN logs, full resources
```

✅ **แยก secrets ตาม environment**
```bash
# AWS Secrets Manager
/myapp/dev/database-url
/myapp/uat/database-url
/myapp/prod/database-url
```

### 2. Deployment Strategy

✅ **DEV**: Rolling deployment, fast feedback
```yaml
deployment-configuration:
  maximumPercent: 200
  minimumHealthyPercent: 50
```

✅ **UAT**: Rolling deployment with health checks
```yaml
deployment-configuration:
  maximumPercent: 200
  minimumHealthyPercent: 100
```

✅ **PROD**: Blue-green deployment
```yaml
deployment-configuration:
  maximumPercent: 200
  minimumHealthyPercent: 100
# + CodeDeploy for blue-green
```

### 3. Testing Strategy

✅ **DEV**:
- Unit tests
- Linting

✅ **UAT**:
- Unit tests
- Integration tests
- Security scanning
- Smoke tests

✅ **PROD**:
- All UAT tests
- E2E tests
- Critical vulnerability blocking
- Production smoke tests
- Monitoring verification

### 4. Security

✅ **Image scanning** ทุก environment
```bash
aws ecr start-image-scan --repository-name $ECR_REPOSITORY
```

✅ **Block critical vulnerabilities** ใน PROD
```bash
if [ "$CRITICAL_FINDINGS" -gt 0 ]; then
  exit 1
fi
```

✅ **Use secrets management**
```yaml
secrets:
  - name: DATABASE_URL
    valueFrom: arn:aws:secretsmanager:...
```

### 5. Monitoring

✅ **CloudWatch Logs** ทุก environment
```json
{
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "/ecs/myapp-prod"
    }
  }
}
```

✅ **Metrics และ Alerting** สำหรับ PROD
- Prometheus + Grafana
- CloudWatch Alarms
- Error rate monitoring
- Response time tracking

### 6. Rollback Strategy

✅ **เก็บ previous task definitions**
```bash
# Backup before deployment
aws ecs describe-task-definition --task-definition $SERVICE > backup.json
```

✅ **Quick rollback script**
```bash
./rollback-prod.sh $PREVIOUS_TASK_DEF
```

✅ **Auto-rollback on failure** (PROD only)
```yaml
- name: Rollback on failure
  if: failure()
  run: |
    aws ecs update-service --force-new-deployment
```

## 📊 Workflow Comparison

| Feature | DEV | UAT | PROD |
|---------|-----|-----|------|
| Auto Deploy | ✅ | ✅ | ✅ |
| Manual Approval | ❌ | Optional | ✅ |
| Unit Tests | ✅ | ✅ | ✅ |
| Integration Tests | ❌ | ✅ | ✅ |
| E2E Tests | ❌ | ❌ | ✅ |
| Security Scan | Basic | Full | Full + Blocking |
| Smoke Tests | ❌ | ✅ | ✅ |
| Blue-Green | ❌ | ❌ | ✅ |
| Auto Rollback | ❌ | ❌ | ✅ |
| Resources | Small | Medium | Large |
| Log Level | DEBUG | INFO | WARN |
| Monitoring | Basic | Basic | Full |

## 🔗 ทรัพยากรเพิ่มเติม

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Blue-Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)

## 💡 Tips

1. **ทดสอบใน DEV ก่อนเสมอ** - Deploy และทดสอบใน DEV environment ก่อน push ไป UAT
2. **ใช้ feature branches** - สร้าง feature branch แล้ว merge เข้า develop → uat → main
3. **Tag releases** - ใช้ semantic versioning (v1.0.0) สำหรับ production releases
4. **Monitor metrics** - ติดตาม metrics และ logs หลัง deployment
5. **Keep backups** - เก็บ database backups และ task definition backups
6. **Document changes** - เขียน changelog สำหรับทุก release

## 🚨 Troubleshooting

### Deployment ล้มเหลว

```bash
# ดู service events
aws ecs describe-services \
    --cluster myapp-prod-cluster \
    --services myapp-prod-service \
    --query 'services[0].events[0:10]'

# ดู task logs
aws logs tail /ecs/myapp-prod --follow
```

### Image scan พบ vulnerabilities

```bash
# ดู scan results
aws ecr describe-image-scan-findings \
    --repository-name myapp-prod \
    --image-id imageTag=latest

# แก้ไข vulnerabilities แล้ว rebuild
npm audit fix
docker build -t myapp:fixed .
```

### Service ไม่ stable

```bash
# ตรวจสอบ health check
aws ecs describe-task-definition \
    --task-definition myapp-prod-task \
    --query 'taskDefinition.containerDefinitions[0].healthCheck'

# ดู running tasks
aws ecs list-tasks \
    --cluster myapp-prod-cluster \
    --service-name myapp-prod-service
```

---

**Happy Deploying! 🚀**
