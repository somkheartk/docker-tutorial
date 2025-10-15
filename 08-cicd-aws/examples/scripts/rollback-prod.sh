#!/bin/bash
set -e

# Rollback Production Deployment
# Usage: ./rollback-prod.sh [task-definition-arn]

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
ECS_CLUSTER="myapp-prod-cluster"
ECS_SERVICE="myapp-prod-service"
ROLLBACK_TO_TASK_DEF="${1}"

echo -e "${RED}================================${NC}"
echo -e "${RED}Rolling Back PRODUCTION${NC}"
echo -e "${RED}================================${NC}"

# Confirmation prompt
read -p "Are you sure you want to rollback PRODUCTION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 1
fi

# Get current task definition if not provided
if [ -z "$ROLLBACK_TO_TASK_DEF" ]; then
    echo -e "${YELLOW}Getting previous task definition...${NC}"
    
    # Get all task definitions for the family
    TASK_FAMILY=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION \
        --query 'services[0].taskDefinition' \
        --output text | cut -d'/' -f2 | cut -d':' -f1)
    
    # Get list of task definitions
    TASK_DEFS=$(aws ecs list-task-definitions \
        --family-prefix $TASK_FAMILY \
        --sort DESC \
        --max-items 5 \
        --region $AWS_REGION \
        --query 'taskDefinitionArns' \
        --output text)
    
    echo "Available task definitions (recent 5):"
    echo "$TASK_DEFS"
    
    echo ""
    read -p "Enter the task definition ARN to rollback to: " ROLLBACK_TO_TASK_DEF
fi

echo -e "${YELLOW}Rolling back to: $ROLLBACK_TO_TASK_DEF${NC}"

# Verify task definition exists
aws ecs describe-task-definition \
    --task-definition $ROLLBACK_TO_TASK_DEF \
    --region $AWS_REGION > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Task definition not found!${NC}"
    exit 1
fi

# Update service to previous task definition
echo -e "${YELLOW}Updating ECS service...${NC}"
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --task-definition $ROLLBACK_TO_TASK_DEF \
    --force-new-deployment \
    --region $AWS_REGION

# Wait for service to stabilize
echo -e "${YELLOW}Waiting for service to stabilize...${NC}"
echo "This may take several minutes..."

# Monitor rollback
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

# Verify rollback
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION \
    --query 'services[0].deployments[?status==`PRIMARY`].taskDefinition' \
    --output text)

if [[ "$CURRENT_TASK_DEF" == *"$ROLLBACK_TO_TASK_DEF"* ]]; then
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Rollback successful!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo "Current task definition: $CURRENT_TASK_DEF"
else
    echo -e "${RED}================================${NC}"
    echo -e "${RED}❌ Rollback verification failed!${NC}"
    echo -e "${RED}================================${NC}"
    echo "Current: $CURRENT_TASK_DEF"
    echo "Expected: $ROLLBACK_TO_TASK_DEF"
    exit 1
fi
