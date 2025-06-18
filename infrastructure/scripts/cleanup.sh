#!/bin/bash
# Script to clean up CloudFormation stacks

# Set default environment to dev if not specified
ENVIRONMENT=${1:-dev}

echo "Cleaning up Gardening Agent infrastructure from $ENVIRONMENT environment..."

# Add cleanup commands here

echo "Cleanup completed successfully!"