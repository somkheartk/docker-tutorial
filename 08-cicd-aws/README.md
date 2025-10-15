# 08. CI/CD บน AWS

## Overview

ในบทนี้เราจะเรียนรู้การสร้าง CI/CD Pipeline สำหรับ Docker Application บน AWS โดยใช้:
- **ECR (Elastic Container Registry)** - Docker image registry
- **ECS (Elastic Container Service)** - Container orchestration
- **GitHub Actions** - CI/CD pipeline
- **AWS CLI** - Command line tools

## AWS Services สำหรับ Container

### 1. ECR (Elastic Container Registry)
- Private Docker registry
- รองรับ Docker image scanning
- Integration กับ ECS, EKS
- Pay per GB stored

### 2. ECS (Elastic Container Service)
- Managed container orchestration service
- รัน containers บน EC2 หรือ Fargate
- Auto scaling
- Load balancing

### 3. Fargate
- Serverless compute สำหรับ containers
- ไม่ต้องจัดการ EC2 instances
- Pay per use

### 4. EKS (Elastic Kubernetes Service)
- Managed Kubernetes service
- สำหรับ production workloads ขนาดใหญ่

## Prerequisites

```bash
# 1. AWS Account
# สมัครที่ https://aws.amazon.com/

# 2. AWS CLI
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# ตรวจสอบ
aws --version

# 3. Configure AWS CLI
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json

# 4. ตรวจสอบการตั้งค่า
aws sts get-caller-identity
```

## 🎯 Workshop: Complete CI/CD Pipeline

### Phase 1: Setup ECR (Container Registry)

#### 1.1 สร้าง ECR Repository

```bash
# สร้าง ECR repository
aws ecr create-repository \
    --repository-name myapp \
    --region us-east-1 \
    --image-scanning-configuration scanOnPush=true

# ดู repositories
aws ecr describe-repositories

# Output จะมี repositoryUri เช่น:
# 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
```

#### 1.2 Login to ECR

```bash
# Get login password และ login
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789012.dkr.ecr.us-east-1.amazonaws.com

# หรือใช้คำสั่งเดียว (Docker 20.10+)
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    $(aws ecr describe-repositories --repository-names myapp --query 'repositories[0].repositoryUri' --output text | cut -d'/' -f1)
```

#### 1.3 Push Image to ECR

```bash
# Build image
docker build -t myapp:latest .

# Tag image
docker tag myapp:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker tag myapp:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# Push image
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# List images
aws ecr list-images --repository-name myapp

# Describe image
aws ecr describe-images --repository-name myapp
```

### Phase 2: Setup ECS (Container Service)

#### 2.1 สร้าง ECS Cluster

```bash
# สร้าง Fargate cluster
aws ecs create-cluster \
    --cluster-name myapp-cluster \
    --region us-east-1

# ดู clusters
aws ecs list-clusters
aws ecs describe-clusters --clusters myapp-cluster
```

#### 2.2 สร้าง Task Definition

**task-definition.json**
```json
{
  "family": "myapp-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "myapp",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-password-xxxxx"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/myapp",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ],
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole"
}
```

```bash
# สร้าง CloudWatch Log Group
aws logs create-log-group --log-group-name /ecs/myapp

# Register task definition
aws ecs register-task-definition \
    --cli-input-json file://task-definition.json

# ดู task definitions
aws ecs list-task-definitions
```

#### 2.3 สร้าง ECS Service

```bash
# สร้าง service
aws ecs create-service \
    --cluster myapp-cluster \
    --service-name myapp-service \
    --task-definition myapp-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxxxx,containerName=myapp,containerPort=3000"

# ดู services
aws ecs list-services --cluster myapp-cluster

# ดูรายละเอียด service
aws ecs describe-services \
    --cluster myapp-cluster \
    --services myapp-service
```

### Phase 3: Setup GitHub Actions CI/CD

#### 3.1 เตรียม AWS Credentials

```bash
# สร้าง IAM User สำหรับ GitHub Actions
aws iam create-user --user-name github-actions

# Attach policies
aws iam attach-user-policy \
    --user-name github-actions \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
    --user-name github-actions \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# สร้าง Access Key
aws iam create-access-key --user-name github-actions

# บันทึก Access Key ID และ Secret Access Key
```

#### 3.2 ตั้งค่า GitHub Secrets

ใน GitHub Repository ไปที่ Settings > Secrets and variables > Actions

เพิ่ม secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (เช่น us-east-1)
- `ECR_REPOSITORY` (เช่น myapp)
- `ECS_CLUSTER` (เช่น myapp-cluster)
- `ECS_SERVICE` (เช่น myapp-service)
- `ECS_TASK_DEFINITION` (path ไปยัง task definition file)

#### 3.3 สร้าง GitHub Actions Workflow

**.github/workflows/deploy.yml**
```yaml
name: Deploy to AWS ECS

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: myapp
  ECS_SERVICE: myapp-service
  ECS_CLUSTER: myapp-cluster
  ECS_TASK_DEFINITION: task-definition.json
  CONTAINER_NAME: myapp

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linting
        run: npm run lint

  build-and-push:
    name: Build and Push to ECR
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    outputs:
      image: ${{ steps.build-image.outputs.image }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          # Build Docker image
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          
          # Push images
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          
          # Output image URI
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

      - name: Scan image for vulnerabilities
        run: |
          aws ecr start-image-scan --repository-name $ECR_REPOSITORY --image-id imageTag=${{ github.sha }}

  deploy:
    name: Deploy to ECS
    runs-on: ubuntu-latest
    needs: build-and-push
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Fill in the new image ID in the Amazon ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ env.ECS_TASK_DEFINITION }}
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ needs.build-and-push.outputs.image }}

      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true

      - name: Notify deployment
        run: |
          echo "✅ Deployment successful!"
          echo "Image: ${{ needs.build-and-push.outputs.image }}"
```

### Phase 4: Load Balancer Setup

#### 4.1 สร้าง Application Load Balancer

```bash
# สร้าง ALB
aws elbv2 create-load-balancer \
    --name myapp-alb \
    --subnets subnet-xxxxx subnet-yyyyy \
    --security-groups sg-xxxxx \
    --scheme internet-facing \
    --type application

# สร้าง Target Group
aws elbv2 create-target-group \
    --name myapp-tg \
    --protocol HTTP \
    --port 3000 \
    --vpc-id vpc-xxxxx \
    --target-type ip \
    --health-check-enabled \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3

# สร้าง Listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/myapp-alb/xxxxx \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/myapp-tg/xxxxx
```

### Phase 5: Monitoring และ Logging

#### 5.1 CloudWatch Logs

```bash
# ดู logs
aws logs tail /ecs/myapp --follow

# Query logs
aws logs filter-log-events \
    --log-group-name /ecs/myapp \
    --filter-pattern "ERROR"
```

#### 5.2 CloudWatch Alarms

```bash
# สร้าง alarm สำหรับ CPU utilization
aws cloudwatch put-metric-alarm \
    --alarm-name myapp-high-cpu \
    --alarm-description "Alert when CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster

# สร้าง alarm สำหรับ Memory utilization
aws cloudwatch put-metric-alarm \
    --alarm-name myapp-high-memory \
    --alarm-description "Alert when Memory exceeds 80%" \
    --metric-name MemoryUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --dimensions Name=ServiceName,Value=myapp-service Name=ClusterName,Value=myapp-cluster
```

## Best Practices

### 1. Security
- ✅ ใช้ IAM Roles แทน hardcode credentials
- ✅ Store secrets ใน AWS Secrets Manager หรือ Parameter Store
- ✅ Enable ECR image scanning
- ✅ ใช้ VPC endpoints สำหรับ ECR และ ECS
- ✅ Encrypt data at rest และ in transit

### 2. Cost Optimization
- ✅ ใช้ Fargate Spot สำหรับ non-critical workloads
- ✅ กำหนด resource limits ที่เหมาะสม
- ✅ ใช้ Auto Scaling
- ✅ ลบ old ECR images

### 3. Performance
- ✅ ใช้ CDN (CloudFront) สำหรับ static assets
- ✅ Enable ALB access logs
- ✅ ตั้งค่า health checks ที่เหมาะสม
- ✅ ใช้ Application Auto Scaling

### 4. Reliability
- ✅ Deploy ใน multiple availability zones
- ✅ ตั้งค่า auto scaling policies
- ✅ ใช้ blue-green deployments
- ✅ มี rollback strategy

## Scripts ที่มีประโยชน์

### deploy.sh
```bash
#!/bin/bash
set -e

# Variables
AWS_REGION="us-east-1"
ECR_REPOSITORY="myapp"
ECS_CLUSTER="myapp-cluster"
ECS_SERVICE="myapp-service"
IMAGE_TAG="${1:-latest}"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR login
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image
echo "Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image
docker tag $ECR_REPOSITORY:$IMAGE_TAG \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Push image
echo "Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Update ECS service
echo "Updating ECS service..."
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --force-new-deployment \
    --region $AWS_REGION

echo "✅ Deployment initiated!"
```

### cleanup.sh
```bash
#!/bin/bash
set -e

# Variables
ECR_REPOSITORY="myapp"
KEEP_COUNT=10

# Get images older than KEEP_COUNT
OLD_IMAGES=$(aws ecr describe-images \
    --repository-name $ECR_REPOSITORY \
    --query "sort_by(imageDetails,& imagePushedAt)[:-${KEEP_COUNT}].imageDigest" \
    --output text)

# Delete old images
if [ -n "$OLD_IMAGES" ]; then
    for digest in $OLD_IMAGES; do
        echo "Deleting image: $digest"
        aws ecr batch-delete-image \
            --repository-name $ECR_REPOSITORY \
            --image-ids imageDigest=$digest
    done
    echo "✅ Cleanup completed!"
else
    echo "No images to delete"
fi
```

## 📝 สรุป

ในบทนี้เราได้เรียนรู้:
- ✅ การใช้ AWS ECR สำหรับเก็บ Docker images
- ✅ การ deploy containers ด้วย AWS ECS
- ✅ การสร้าง CI/CD pipeline ด้วย GitHub Actions
- ✅ การตั้งค่า Load Balancer และ Auto Scaling
- ✅ Monitoring และ Logging บน AWS
- ✅ Security และ Cost optimization best practices

## 🎓 แบบฝึกหัด

1. สร้าง complete CI/CD pipeline สำหรับ application ของคุณ
2. ตั้งค่า blue-green deployment strategy
3. เพิ่ม automated testing ใน pipeline
4. ตั้งค่า CloudWatch alarms และ notifications
5. ทดสอบ rollback strategy

## 🎉 สรุปทั้งหมด

ยินดีด้วย! คุณได้เรียนรู้ Docker ตั้งแต่พื้นฐานจนถึงการ deploy บน production AWS แล้ว

**สิ่งที่เราได้เรียนรู้:**
1. ✅ Docker basics และ fundamentals
2. ✅ การสร้าง Dockerfile และ images
3. ✅ Docker Compose สำหรับ multi-container apps
4. ✅ Networking และ Volumes
5. ✅ Optimization และ multi-stage builds
6. ✅ Security best practices
7. ✅ Advanced topics (Swarm, monitoring, logging)
8. ✅ CI/CD บน AWS

**ขั้นตอนต่อไป:**
- ลองใช้ Kubernetes (EKS)
- เรียนรู้ Infrastructure as Code (Terraform, CloudFormation)
- ศึกษา Microservices architecture
- ดู Service Mesh (Istio, Linkerd)

---

**Happy Docker! 🐳**

**ขอบคุณที่เรียนจบคอร์ส!**
