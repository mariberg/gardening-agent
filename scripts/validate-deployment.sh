#!/bin/bash

# Deployment Validation Script for Gardening Agent Infrastructure
# This script validates CloudFormation templates and parameter files before deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_FILE="cloudformation/infrastructure.yaml"
PARAMETERS_DIR="cloudformation/parameters"
STACK_NAME="gardening-agent"

echo -e "${BLUE}=== Gardening Agent Deployment Validation ===${NC}"
echo

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    print_status "Checking AWS CLI installation and configuration..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or credentials are invalid."
        echo "Run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    print_success "AWS CLI is properly configured"
    aws sts get-caller-identity --query 'Account' --output text | xargs -I {} echo "Using AWS Account: {}"
    echo
}

# Validate CloudFormation template syntax
validate_template() {
    print_status "Validating CloudFormation template syntax..."
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi
    
    if aws cloudformation validate-template --template-body file://$TEMPLATE_FILE &> /dev/null; then
        print_success "CloudFormation template syntax is valid"
    else
        print_error "CloudFormation template validation failed"
        echo "Running validation with detailed output:"
        aws cloudformation validate-template --template-body file://$TEMPLATE_FILE
        exit 1
    fi
    echo
}

# Validate parameter files
validate_parameters() {
    print_status "Validating parameter files..."
    
    if [ ! -d "$PARAMETERS_DIR" ]; then
        print_error "Parameters directory not found: $PARAMETERS_DIR"
        exit 1
    fi
    
    local param_files_found=false
    
    for param_file in "$PARAMETERS_DIR"/*.json; do
        if [ -f "$param_file" ]; then
            param_files_found=true
            local filename=$(basename "$param_file")
            print_status "Validating parameter file: $filename"
            
            # Check if it's valid JSON
            if jq empty "$param_file" 2>/dev/null; then
                print_success "Parameter file $filename has valid JSON syntax"
                
                # Validate parameter structure
                if jq -e 'type == "array" and all(type == "object" and has("ParameterKey") and has("ParameterValue"))' "$param_file" > /dev/null; then
                    print_success "Parameter file $filename has correct structure"
                    
                    # Show parameter summary
                    echo "Parameters in $filename:"
                    jq -r '.[] | "  - \(.ParameterKey): \(.ParameterValue)"' "$param_file"
                else
                    print_error "Parameter file $filename has incorrect structure"
                    echo "Expected format: [{\"ParameterKey\": \"key\", \"ParameterValue\": \"value\"}, ...]"
                    exit 1
                fi
            else
                print_error "Parameter file $filename contains invalid JSON"
                exit 1
            fi
            echo
        fi
    done
    
    if [ "$param_files_found" = false ]; then
        print_warning "No parameter files found in $PARAMETERS_DIR"
        echo "You may need to create parameter files for your environments."
        echo
    fi
}

# Check for required tools
check_dependencies() {
    print_status "Checking required dependencies..."
    
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing tools:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                jq)
                    echo "  - jq: brew install jq (macOS) or apt-get install jq (Ubuntu)"
                    ;;
            esac
        done
        exit 1
    fi
    
    print_success "All required dependencies are installed"
    echo
}

# Display deployment commands
show_deployment_commands() {
    print_status "Basic deployment commands reference:"
    echo
    echo -e "${YELLOW}1. Deploy new stack:${NC}"
    echo "   aws cloudformation create-stack \\"
    echo "     --stack-name $STACK_NAME-dev \\"
    echo "     --template-body file://$TEMPLATE_FILE \\"
    echo "     --parameters file://$PARAMETERS_DIR/dev.json \\"
    echo "     --capabilities CAPABILITY_NAMED_IAM"
    echo
    echo -e "${YELLOW}2. Update existing stack:${NC}"
    echo "   aws cloudformation update-stack \\"
    echo "     --stack-name $STACK_NAME-dev \\"
    echo "     --template-body file://$TEMPLATE_FILE \\"
    echo "     --parameters file://$PARAMETERS_DIR/dev.json \\"
    echo "     --capabilities CAPABILITY_NAMED_IAM"
    echo
    echo -e "${YELLOW}3. Check stack status:${NC}"
    echo "   aws cloudformation describe-stacks \\"
    echo "     --stack-name $STACK_NAME-dev \\"
    echo "     --query 'Stacks[0].StackStatus'"
    echo
    echo -e "${YELLOW}4. Delete stack:${NC}"
    echo "   aws cloudformation delete-stack \\"
    echo "     --stack-name $STACK_NAME-dev"
    echo
    echo -e "${YELLOW}5. Monitor stack events:${NC}"
    echo "   aws cloudformation describe-stack-events \\"
    echo "     --stack-name $STACK_NAME-dev \\"
    echo "     --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' \\"
    echo "     --output table"
    echo
}

# Main execution
main() {
    check_dependencies
    check_aws_cli
    validate_template
    validate_parameters
    
    print_success "All validations passed successfully!"
    echo
    show_deployment_commands
    
    print_status "Validation complete. Your CloudFormation template and parameters are ready for deployment."
}

# Run main function
main "$@"