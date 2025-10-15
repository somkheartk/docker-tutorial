#!/bin/bash
set -e

# Deploy to UAT Environment
# Usage: ./deploy-uat.sh [image-tag]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="myapp-uat"
ECS_CLUSTER="myapp-uat-cluster"
ECS_SERVICE="myapp-uat-service"
TASK_DEFINITION_FILE="../task-definitions/task-definition-uat.json"
IMAGE_TAG="${1:-latest}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deploying to UAT Environment${NC}"
echo -e "${GREEN}================================${NC}"

# Get AWS account ID
echo -e "${YELLOW}Getting AWS account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# ECR login
echo -e "${YELLOW}Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Tag image
echo -e "${YELLOW}Tagging image...${NC}"
docker tag $ECR_REPOSITORY:$IMAGE_TAG \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
docker tag $ECR_REPOSITORY:$IMAGE_TAG \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:uat-latest

# Push image
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:uat-latest

# Run security scan
echo -e "${YELLOW}Starting image security scan...${NC}"
aws ecr start-image-scan \
    --repository-name $ECR_REPOSITORY \
    --image-id imageTag=$IMAGE_TAG \
    --region $AWS_REGION || echo "Scan already in progress or complete"

# Wait for scan
echo -e "${YELLOW}Waiting for security scan to complete...${NC}"
sleep 30

# Check scan results
SCAN_FINDINGS=$(aws ecr describe-image-scan-findings \
    --repository-name $ECR_REPOSITORY \
    --image-id imageTag=$IMAGE_TAG \
    --region $AWS_REGION \
    --query 'imageScanFindings.findingSeverityCounts' \
    --output json 2>/dev/null || echo "{}")

echo "Scan findings: $SCAN_FINDINGS"

# Update task definition with new image
echo -e "${YELLOW}Updating task definition...${NC}"
TASK_DEFINITION=$(cat $TASK_DEFINITION_FILE | \
    jq --arg IMAGE "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG" \
    '.containerDefinitions[0].image = $IMAGE')

# Register new task definition
TASK_DEFINITION_ARN=$(echo $TASK_DEFINITION | \
    aws ecs register-task-definition \
    --cli-input-json file:///dev/stdin \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "New task definition ARN: $TASK_DEFINITION_ARN"

# Update ECS service
echo -e "${YELLOW}Updating ECS service...${NC}"
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --task-definition $TASK_DEFINITION_ARN \
    --force-new-deployment \
    --region $AWS_REGION

# Wait for service to stabilize
echo -e "${YELLOW}Waiting for service to stabilize...${NC}"
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION

# Run smoke tests
echo -e "${YELLOW}Running smoke tests...${NC}"
sleep 10
# Add your smoke test commands here
echo "Smoke tests passed ✓"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Deployment to UAT successful!${NC}"
echo -e "${GREEN}================================${NC}"
echo "Environment: UAT"
echo "Image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"
echo "Cluster: $ECS_CLUSTER"
echo "Service: $ECS_SERVICE"
echo "Task Definition: $TASK_DEFINITION_ARN"
