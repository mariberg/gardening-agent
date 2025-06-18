#!/bin/bash
# Script to deploy CloudFormation stacks

# Set default environment to dev if not specified
ENVIRONMENT=${1:-dev}

echo "Deploying Gardening Agent infrastructure to $ENVIRONMENT environment..."

# Add deployment commands here

echo "Deployment completed successfully!"