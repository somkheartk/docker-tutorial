#!/bin/bash
set -e

# Deploy to Dev Environment
# Usage: ./deploy-dev.sh [image-tag]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="myapp-dev"
ECS_CLUSTER="myapp-dev-cluster"
ECS_SERVICE="myapp-dev-service"
TASK_DEFINITION_FILE="../task-definitions/task-definition-dev.json"
IMAGE_TAG="${1:-latest}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deploying to DEV Environment${NC}"
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
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:dev-latest

# Push image
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:dev-latest

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

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Deployment to DEV successful!${NC}"
echo -e "${GREEN}================================${NC}"
echo "Environment: DEV"
echo "Image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"
echo "Cluster: $ECS_CLUSTER"
echo "Service: $ECS_SERVICE"
echo "Task Definition: $TASK_DEFINITION_ARN"
