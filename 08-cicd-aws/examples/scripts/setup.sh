#!/bin/bash
set -e

# Setup script for multi-environment CI/CD
# Usage: ./setup.sh

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Multi-Environment CI/CD Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI not found. Please install it first.${NC}"
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI found${NC}"

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo -e "${YELLOW}AWS Account ID:${NC} $AWS_ACCOUNT_ID"
echo -e "${YELLOW}AWS Region:${NC} $AWS_REGION"
echo ""

# Confirm
read -p "Continue with setup? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Setup cancelled"
    exit 0
fi

echo ""
echo -e "${BLUE}Step 1: Creating ECR Repositories${NC}"
echo "-----------------------------------"

for env in dev uat prod; do
    REPO_NAME="myapp-$env"
    echo -e "${YELLOW}Creating repository: $REPO_NAME${NC}"
    
    if aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION &> /dev/null; then
        echo -e "${GREEN}✓ Repository $REPO_NAME already exists${NC}"
    else
        aws ecr create-repository \
            --repository-name $REPO_NAME \
            --region $AWS_REGION \
            --image-scanning-configuration scanOnPush=true \
            --query 'repository.repositoryUri' \
            --output text
        echo -e "${GREEN}✓ Repository $REPO_NAME created${NC}"
    fi
done

echo ""
echo -e "${BLUE}Step 2: Creating ECS Clusters${NC}"
echo "-------------------------------"

for env in dev uat prod; do
    CLUSTER_NAME="myapp-$env-cluster"
    echo -e "${YELLOW}Creating cluster: $CLUSTER_NAME${NC}"
    
    if aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION --query 'clusters[0].status' --output text | grep -q "ACTIVE"; then
        echo -e "${GREEN}✓ Cluster $CLUSTER_NAME already exists${NC}"
    else
        aws ecs create-cluster \
            --cluster-name $CLUSTER_NAME \
            --region $AWS_REGION \
            --query 'cluster.clusterName' \
            --output text
        echo -e "${GREEN}✓ Cluster $CLUSTER_NAME created${NC}"
    fi
done

echo ""
echo -e "${BLUE}Step 3: Creating IAM User for GitHub Actions${NC}"
echo "----------------------------------------------"

IAM_USER="github-actions-cicd"
echo -e "${YELLOW}Creating IAM user: $IAM_USER${NC}"

if aws iam get-user --user-name $IAM_USER &> /dev/null; then
    echo -e "${GREEN}✓ IAM user $IAM_USER already exists${NC}"
else
    aws iam create-user --user-name $IAM_USER
    echo -e "${GREEN}✓ IAM user $IAM_USER created${NC}"
fi

# Attach policies
echo -e "${YELLOW}Attaching policies...${NC}"

aws iam attach-user-policy \
    --user-name $IAM_USER \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
    --user-name $IAM_USER \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

echo -e "${GREEN}✓ Policies attached${NC}"

# Create access key
echo ""
echo -e "${YELLOW}Creating access key...${NC}"
echo -e "${RED}IMPORTANT: Save these credentials securely!${NC}"
echo ""

ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $IAM_USER --output json 2>&1)

if echo "$ACCESS_KEY_OUTPUT" | grep -q "EntityAlreadyExists"; then
    echo -e "${YELLOW}Access key already exists for this user.${NC}"
    echo -e "${YELLOW}Please delete old access key or use existing credentials.${NC}"
else
    echo "$ACCESS_KEY_OUTPUT" | jq -r '
        "AWS_ACCESS_KEY_ID: " + .AccessKey.AccessKeyId,
        "AWS_SECRET_ACCESS_KEY: " + .AccessKey.SecretAccessKey
    '
fi

echo ""
echo -e "${BLUE}Step 4: Creating CloudWatch Log Groups${NC}"
echo "----------------------------------------"

for env in dev uat prod; do
    LOG_GROUP="/ecs/myapp-$env"
    echo -e "${YELLOW}Creating log group: $LOG_GROUP${NC}"
    
    if aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $AWS_REGION --query 'logGroups[0].logGroupName' --output text | grep -q "$LOG_GROUP"; then
        echo -e "${GREEN}✓ Log group $LOG_GROUP already exists${NC}"
    else
        aws logs create-log-group \
            --log-group-name $LOG_GROUP \
            --region $AWS_REGION
        
        # Set retention
        aws logs put-retention-policy \
            --log-group-name $LOG_GROUP \
            --retention-in-days 30 \
            --region $AWS_REGION
        
        echo -e "${GREEN}✓ Log group $LOG_GROUP created${NC}"
    fi
done

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Add AWS credentials to GitHub Secrets:"
echo "   - AWS_ACCESS_KEY_ID_DEV"
echo "   - AWS_SECRET_ACCESS_KEY_DEV"
echo "   - AWS_ACCESS_KEY_ID_UAT"
echo "   - AWS_SECRET_ACCESS_KEY_UAT"
echo "   - AWS_ACCESS_KEY_ID_PROD"
echo "   - AWS_SECRET_ACCESS_KEY_PROD"
echo ""
echo "2. Update task definition files with your AWS Account ID:"
echo "   - task-definitions/task-definition-dev.json"
echo "   - task-definitions/task-definition-uat.json"
echo "   - task-definitions/task-definition-prod.json"
echo ""
echo "3. Copy workflow files to .github/workflows/"
echo "   cp workflows/*.yml ../../.github/workflows/"
echo ""
echo "4. Create GitHub Environments (Settings > Environments):"
echo "   - dev"
echo "   - uat"
echo "   - production (with required reviewers)"
echo ""
echo "5. Push to trigger deployments:"
echo "   git push origin develop  # Deploy to DEV"
echo "   git push origin uat       # Deploy to UAT"
echo "   git push origin main      # Deploy to PROD"
echo ""
echo -e "${GREEN}Happy deploying! 🚀${NC}"
