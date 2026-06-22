#!/bin/bash
# Script to deploy the CloudFormation stack for the Gardening Agent

# Default values
ENVIRONMENT="dev"
STACK_NAME="gardening-agent"
REGION="eu-west-2"  # Default region from agent.py
S3_BUCKET=""        # S3 bucket for storing templates and code

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --env)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    --stack-name)
      STACK_NAME="$2"
      shift
      shift
      ;;
    --region)
      REGION="$2"
      shift
      shift
      ;;
    --s3-bucket)
      S3_BUCKET="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$S3_BUCKET" ]; then
  echo "Error: S3 bucket name is required. Use --s3-bucket parameter."
  exit 1
fi

# Set paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$INFRA_DIR/templates"
PARAMETERS_FILE="$INFRA_DIR/parameters/$ENVIRONMENT.json"
PROJECT_ROOT="$(dirname "$INFRA_DIR")"

echo "Deploying Gardening Agent infrastructure..."
echo "Environment: $ENVIRONMENT"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "S3 Bucket: $S3_BUCKET"

# Package Lambda code
echo "Packaging Lambda function..."
mkdir -p "$PROJECT_ROOT/build"
cp "$PROJECT_ROOT/agent.py" "$PROJECT_ROOT/build/"
cd "$PROJECT_ROOT/build"
zip -r function.zip agent.py
aws s3 cp function.zip "s3://$S3_BUCKET/$STACK_NAME/function.zip"

# Package Lambda layer
echo "Packaging Lambda layer..."
mkdir -p "$PROJECT_ROOT/build/python"
pip install -r "$PROJECT_ROOT/lambda-layer/requirements.txt" -t "$PROJECT_ROOT/build/python"
cd "$PROJECT_ROOT/build"
zip -r layer.zip python/
aws s3 cp layer.zip "s3://$S3_BUCKET/$STACK_NAME/layer.zip"

# Package CloudFormation templates
echo "Packaging CloudFormation templates..."
aws cloudformation package \
  --template-file "$TEMPLATES_DIR/main.yaml" \
  --s3-bucket "$S3_BUCKET" \
  --s3-prefix "$STACK_NAME/templates" \
  --output-template-file "$PROJECT_ROOT/build/packaged-template.yaml"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/build/packaged-template.yaml" \
  --stack-name "$STACK_NAME-$ENVIRONMENT" \
  --parameter-overrides file://"$PARAMETERS_FILE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION"

# Clean up
echo "Cleaning up build directory..."
rm -rf "$PROJECT_ROOT/build"

echo "Deployment complete!"