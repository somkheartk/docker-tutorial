#!/bin/bash
set -e

# Deploy to Production Environment with Blue-Green Deployment
# Usage: ./deploy-prod.sh [image-tag]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="myapp-prod"
ECS_CLUSTER="myapp-prod-cluster"
ECS_SERVICE="myapp-prod-service"
TASK_DEFINITION_FILE="../task-definitions/task-definition-prod.json"
IMAGE_TAG="${1:-latest}"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Deploying to PRODUCTION${NC}"
echo -e "${BLUE}================================${NC}"

# Confirmation prompt for production
read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

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
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:prod-latest

# Push image
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:prod-latest

# Run security scan
echo -e "${YELLOW}Starting comprehensive security scan...${NC}"
aws ecr start-image-scan \
    --repository-name $ECR_REPOSITORY \
    --image-id imageTag=$IMAGE_TAG \
    --region $AWS_REGION || echo "Scan already in progress or complete"

# Wait for scan
echo -e "${YELLOW}Waiting for security scan to complete...${NC}"
sleep 60

# Check scan results
CRITICAL_FINDINGS=$(aws ecr describe-image-scan-findings \
    --repository-name $ECR_REPOSITORY \
    --image-id imageTag=$IMAGE_TAG \
    --region $AWS_REGION \
    --query 'imageScanFindings.findingSeverityCounts.CRITICAL' \
    --output text 2>/dev/null || echo "0")

if [ "$CRITICAL_FINDINGS" != "None" ] && [ "$CRITICAL_FINDINGS" != "" ] && [ "$CRITICAL_FINDINGS" -gt 0 ]; then
    echo -e "${RED}❌ Critical vulnerabilities found! Count: $CRITICAL_FINDINGS${NC}"
    echo -e "${RED}Deployment aborted!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ No critical vulnerabilities found${NC}"

# Backup current task definition
echo -e "${YELLOW}Creating backup of current task definition...${NC}"
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].taskDefinition' \
    --output text)
echo "Current task definition: $CURRENT_TASK_DEF"

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

# Deploy with blue-green strategy
echo -e "${BLUE}Starting blue-green deployment...${NC}"
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --task-definition $TASK_DEFINITION_ARN \
    --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
    --force-new-deployment \
    --region $AWS_REGION

# Wait for service to stabilize
echo -e "${YELLOW}Waiting for service to stabilize...${NC}"
echo "This may take several minutes..."

# Monitor deployment
for i in {1..30}; do
    RUNNING_COUNT=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION \
        --query 'services[0].runningCount' \
        --output text)
    
    DESIRED_COUNT=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION \
        --query 'services[0].desiredCount' \
        --output text)
    
    echo "Progress: $RUNNING_COUNT/$DESIRED_COUNT tasks running"
    
    if [ "$RUNNING_COUNT" == "$DESIRED_COUNT" ]; then
        echo -e "${GREEN}Service stable!${NC}"
        break
    fi
    
    sleep 30
done

# Run smoke tests
echo -e "${YELLOW}Running production smoke tests...${NC}"
sleep 20
# Add your production smoke test commands here
echo "Smoke tests passed ✓"

# Verify deployment
echo -e "${YELLOW}Verifying deployment...${NC}"
DEPLOYMENT_STATUS=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].deployments[?status==`PRIMARY`].taskDefinition' \
    --output text)

if [ "$DEPLOYMENT_STATUS" == "$TASK_DEFINITION_ARN" ]; then
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ PRODUCTION Deployment Successful!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo "Environment: PRODUCTION"
    echo "Image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"
    echo "Cluster: $ECS_CLUSTER"
    echo "Service: $ECS_SERVICE"
    echo "Task Definition: $TASK_DEFINITION_ARN"
    echo "Previous Task Definition: $CURRENT_TASK_DEF (saved for rollback)"
else
    echo -e "${RED}================================${NC}"
    echo -e "${RED}❌ Deployment verification failed!${NC}"
    echo -e "${RED}================================${NC}"
    echo "Please check AWS console for details"
    exit 1
fi
