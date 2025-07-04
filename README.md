## Gardening Agent

This gardening agent has been built using the AWS Strands Agents SDK. The Python code for the agent is located in the `src/agent.py` file and is deployed as an AWS Lambda function. The agent has access to the Amazon Nova Lite AI model and utilizes three tools. The first tool is a Strands built-in tool 'http_request', which the agent can utilize to fetch weather data. In addition there are two custom tools that enable the agent to fetch data from DynamoDB. The agent is able to fetch user data, which contains a list of garden plants the user has. The agent is also able to fetch plant-specific details from a second DynamoDB table. Based on this data, the AI model is able to create tailored weather-related advice for a user's specific plants.

The agent supports both direct Lambda invocation and HTTP API access through API Gateway integration. It automatically detects the event type and handles API Gateway proxy events with proper CORS support, request parsing, and HTTP response formatting.

**API Simplification**: The API has been simplified to accept only a `user_id` parameter instead of requiring full prompt construction. The system automatically handles all data retrieval, prompt construction, and AI interaction internally, making it much easier for frontend applications to integrate.

The agent is integrated with AWS CloudFormation for infrastructure deployment and uses environment variables for configuration, making it easily deployable across different environments.

## Project Structure

```
gardening-agent/
├── src/
│   └── agent.py                    # Main Lambda function code
├── cloudformation/
│   ├── infrastructure.yaml         # CloudFormation template
│   └── parameters/
│       └── dev.json               # Development environment parameters
├── lambda-layer/
│   └── requirements.txt           # Python dependencies
├── images/                        # Documentation images
└── README.md                      # This file
```

![diagram](./images/gardening-agent.png)

The Lambda function is triggered by an event that contains the user ID. The weather system prompt explains the detailed use case of acting as a gardening weather advisor.
The prompt and details of available tools are sent to the AI model and the data is retrieved and combined based on the AI model's plan:

![cloudwatch_logs](./images/cloudwatch_logs.jpg)

Finally, the AI model will create a natural language response which the agent can return to the client:
``
Both plants are currently within their ideal temperature and humidity ranges. However, the forecast shows temperatures 
rising above the ideal range for both plants. Consider providing some shade or shelter to protect them from excessive heat.
``

## Deployment

The project includes Infrastructure as Code (IaC) using AWS CloudFormation. This is the recommended deployment method as it ensures consistent and repeatable deployments.

### Prerequisites
- AWS CLI configured with appropriate permissions
- Access to Amazon Bedrock (Nova Lite model) in your AWS account

### Deploy Infrastructure

#### Validate Before Deployment (Recommended)

Before deploying, you can validate your CloudFormation template and parameters:

```bash
# Run the validation script
./scripts/validate-deployment.sh

# Or skip AWS CLI checks if needed
./scripts/validate-deployment.sh --skip-aws-check
```

This script will:
- Validate CloudFormation template syntax
- Check parameter file structure and content
- Verify AWS CLI configuration
- Display deployment command examples

#### Option 1: Deploy with Local Code (Recommended for Development)

1. **Create the CloudFormation stack:**
```bash
aws cloudformation create-stack \
  --stack-name gardening-agent-dev \
  --template-body file://cloudformation/infrastructure.yaml \
  --parameters file://cloudformation/parameters/dev.json \
  --capabilities CAPABILITY_NAMED_IAM
```

2. **Wait for stack creation to complete:**
```bash
aws cloudformation wait stack-create-complete \
  --stack-name gardening-agent-dev
```

3. **Update the Lambda function code:**
```bash
# Package your code (include dependencies if not using Lambda layers)
zip -r function.zip src/

# Update the function
aws lambda update-function-code \
  --function-name gardening-agent-dev \
  --zip-file fileb://function.zip
```

#### Option 2: Deploy with S3-hosted Code (Recommended for Production)

1. **Package and upload your code to S3:**
```bash
# Create deployment package
zip -r gardening-agent.zip src/

# Upload to S3 (replace with your bucket name)
aws s3 cp gardening-agent.zip s3://your-deployment-bucket/gardening-agent/gardening-agent.zip
```

2. **Create parameter file with S3 configuration:**
```json
[
  {"ParameterKey": "Environment", "ParameterValue": "dev"},
  {"ParameterKey": "UserDataTableName", "ParameterValue": "plant_database_users"},
  {"ParameterKey": "PlantDefinitionsTableName", "ParameterValue": "garden_plants"},
  {"ParameterKey": "LambdaFunctionName", "ParameterValue": "gardening-agent"},
  {"ParameterKey": "BedrockRegion", "ParameterValue": "eu-west-2"},
  {"ParameterKey": "CodeS3Bucket", "ParameterValue": "your-deployment-bucket"},
  {"ParameterKey": "CodeS3Key", "ParameterValue": "gardening-agent/gardening-agent.zip"}
]
```

3. **Deploy the stack with S3 code reference:**
```bash
aws cloudformation create-stack \
  --stack-name gardening-agent-dev \
  --template-body file://cloudformation/infrastructure.yaml \
  --parameters file://cloudformation/parameters/dev-s3.json \
  --capabilities CAPABILITY_NAMED_IAM
```

**Note**: The Lambda function handler is configured as `src.agent.lambda_handler` to match the new project structure. Environment variables for table names and region are automatically set by CloudFormation.

### API Gateway Integration

The Lambda function now supports HTTP API access through API Gateway integration. When deployed with API Gateway, the function automatically detects API Gateway proxy events and handles them appropriately with:

- **Request Parsing**: Extracts JSON payload from API Gateway request body
- **CORS Support**: Includes proper CORS headers for browser-based requests
- **Enhanced Error Handling**: Returns proper HTTP status codes with detailed error messages and request tracking
- **OPTIONS Support**: Handles preflight requests for CORS compliance
- **Response Metadata**: Includes timestamps, request IDs, weather conditions, and user context
- **Request Tracking**: Each request gets a unique request ID for debugging and monitoring

#### API Request Format

When calling through API Gateway, send a POST request with JSON body containing only the user ID:

```json
{
  "user_id": "test_user"
}
```

**User ID Requirements:**
- Must be a string containing only letters, numbers, underscores, and hyphens
- Length must be between 1 and 50 characters
- Cannot be empty or contain only whitespace
- Examples of valid user IDs: `user123`, `test-user`, `my_garden_user`

#### API Response Format

The API returns a structured JSON response with enhanced metadata:

**Success Response:**
```json
{
  "statusCode": 200,
  "advice": "Both plants have generally favorable conditions with some attention needed for humidity management and wind protection.",
  "details": {
    "Rose": "Current temperature is within ideal range. However, humidity is at 85% which may increase risk of black spot. Consider improving air circulation around your roses.",
    "Grapevine": "Temperature conditions are suitable. Wind speeds are forecasted to reach 35 km/h tomorrow, which exceeds tolerance. Consider providing windbreak protection."
  },
  "timestamp": "2025-01-07T10:30:00Z",
  "user_id": "test_user",
  "weather_conditions": {
    "temperature": 22,
    "humidity": 65,
    "condition": "partly_cloudy"
  }
}
```

**Error Response:**
```json
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "User not found: No user profile found for user_id: test_user",
  "request_id": "abc-123-def-456",
  "timestamp": "2025-01-07T10:30:00Z",
  "user_id": "test_user"
}
```

#### Example API Usage

```bash
# Using curl to call the API (note the /dev/advice path structure)
curl -X POST https://your-api-gateway-id.execute-api.region.amazonaws.com/dev/advice \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test_user"}'

# Handle CORS preflight (automatically handled by browsers)
curl -X OPTIONS https://your-api-gateway-id.execute-api.region.amazonaws.com/dev/advice \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"
```

#### HTTP Status Codes

The API returns appropriate HTTP status codes for different scenarios:

- **200 OK**: Successful request with gardening advice
- **400 Bad Request**: Invalid user_id format, missing required fields, or validation errors
- **404 Not Found**: User profile doesn't exist in database
- **500 Internal Server Error**: Database access errors or unexpected internal errors
- **503 Service Unavailable**: AI service (Bedrock), weather service, or database temporarily unavailable

**Enhanced Error Handling:**
- Specific error messages for different failure scenarios (user not found, invalid format, service unavailable)
- Automatic retry suggestions for temporary service issues
- Request ID tracking for all errors to facilitate debugging
- Detailed logging for system administrators while keeping user-facing messages clear
- Graceful degradation when external services are temporarily unavailable

All error responses include detailed error messages, request IDs for tracking, and timestamps for debugging.

#### Update Existing Infrastructure
```bash
aws cloudformation update-stack \
  --stack-name gardening-agent-dev \
  --template-body file://cloudformation/infrastructure.yaml \
  --parameters file://cloudformation/parameters/dev.json \
  --capabilities CAPABILITY_NAMED_IAM
```

#### Get API Gateway Endpoint URL
After deployment, retrieve the API Gateway endpoint URL:
```bash
aws cloudformation describe-stacks \
  --stack-name gardening-agent-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text
```



### Testing the Deployment

After successful deployment, you can test both the Lambda function and API Gateway endpoint:

#### Test Lambda Function Directly
```bash
# Using the simplified user_id format
aws lambda invoke \
  --function-name gardening-agent-dev \
  --payload '{"user_id": "test_user"}' \
  response.json && cat response.json

# Legacy prompt format is still supported for backward compatibility
aws lambda invoke \
  --function-name gardening-agent-dev \
  --payload '{"prompt": "Give me plant advice for user_id test_user"}' \
  response.json && cat response.json
```

**Note**: Direct Lambda invocation returns an enhanced response format that includes `advice`, `details`, `timestamp`, `user_id`, `weather_conditions`, and `request_id` for improved debugging and monitoring.

#### Test API Gateway Endpoint
```bash
# Get the API Gateway URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name gardening-agent-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

# Test the endpoint
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test_user"}'
```

### Access to Bedrock

The Lambda function uses Amazon Nova Lite model and access to this model needs to be requested through the Bedrock console. The CloudFormation template automatically configures the necessary IAM permissions for Bedrock access in the specified region. 


## Infrastructure Components

The CloudFormation template creates the following AWS resources:

- **Lambda Function**: `gardening-agent-dev` running Python 3.13 runtime with proper IAM permissions and environment variable configuration
- **IAM Execution Role**: Comprehensive role with policies for:
  - Basic Lambda execution (CloudWatch Logs)
  - DynamoDB access (GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan)
  - Amazon Bedrock access (InvokeModel, InvokeModelWithResponseStream) for Nova Lite model
- **API Gateway REST API**: Complete API setup including:
  - REST API with regional endpoint configuration
  - `/advice` resource endpoint
  - POST method with Lambda proxy integration
  - OPTIONS method for CORS preflight requests
  - API Gateway deployment and stage management
- **DynamoDB Tables**: Two pay-per-request tables with proper tagging:
  - User data table with `user_id` as primary key
  - Plant definitions table with `plant_id` as primary key
- **Lambda Permissions**: Allows API Gateway to invoke the Lambda function
- **Environment Variables**: Automatically configured for:
  - `USER_DATA_TABLE_NAME`: DynamoDB table name for user data
  - `PLANT_DEFINITIONS_TABLE_NAME`: DynamoDB table name for plant definitions  
  - `BEDROCK_REGION`: AWS region for Bedrock model access

### API Gateway Configuration

The API Gateway is configured with:
- **Stage Variables**: Environment-specific configuration
- **CORS Support**: Proper CORS headers for browser-based requests
## Configuration

The Lambda function now uses environment variables for all configuration, making it environment-agnostic:

- **Table Names**: Dynamically configured via CloudFormation parameters
- **AWS Region**: Configurable for Bedrock access (defaults to `eu-west-2`)
- **Fallback Values**: Default values provided for local development

This approach ensures the same code can be deployed across different environments (dev, staging, prod) without modification.

### CloudFormation Parameters

The infrastructure template supports the following configurable parameters:

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `Environment` | `dev` | Environment name for resource naming (dev/staging/prod) |
| `UserDataTableName` | `plant_database_users` | Name for the user data DynamoDB table |
| `PlantDefinitionsTableName` | `garden_plants` | Name for the plant definitions DynamoDB table |
| `LambdaFunctionName` | `gardening-agent` | Name for the Lambda function |
| `BedrockRegion` | `eu-west-2` | AWS region for Bedrock model access |
| `CodeS3Bucket` | `""` | S3 bucket containing Lambda deployment package (optional) |
| `CodeS3Key` | `""` | S3 key for Lambda deployment package (optional) |

**Note**: The `CodeS3Bucket` and `CodeS3Key` parameters are optional and used for production deployments where code is hosted in S3. For development, the template uses inline placeholder code that gets updated after stack creation.

## DynamoDB Tables

The CloudFormation template automatically creates **two DynamoDB tables**:

---

### 1. `plant_database_users-dev`

- **Primary Key**: `user_id` (String)
- **Purpose**: Stores user location data and their plant lists

#### Example item:

```json
{
  "user_id": "test_user",
  "latitude": "41.8967",
  "longitude": "12.4822",
  "plants": [
    "plant#rose",
    "plant#grapevine"
  ]
}
```

### 2. `garden_plants-dev`

- **Primary Key**: `plant_id` (String)
- **Purpose**: Stores detailed plant characteristics and requirements

#### Example item:

```json
{
  "plant_id": "plant#rose",
  "common_name": "Rose",
  "scientific_name": "Rosa spp.",
  "plant_type": "shrub",
  "min_temp_c": -15,
  "max_temp_c": 35,
  "ideal_temp_range_c": [15, 26],
  "frost_tolerance": true,
  "sunlight_requirement": "full sun",
  "max_daily_sunlight_hours": 10,
  "min_daily_sunlight_hours": 6,
  "watering_frequency_days": 3,
  "soil_moisture_preference": "moist",
  "rainfall_tolerance_mm_per_day": 25,
  "ideal_humidity_range_percent": [40, 70],
  "humidity_tolerance": "moderate",
  "wind_tolerance_kmph": 30,
  "requires_staking": false,
  "soil_type_preference": "loamy",
  "ph_preference": "slightly acidic",
  "drainage_needs": "well-drained",
  "shelter_requirement": false,
  "growing_season": "spring-summer",
  "dormant_season": "winter",
  "last_frost_date_safe_planting": "2024-04-15",
  "first_frost_date_end_of_growth": "2024-10-30",
  "special_weather_notes": "Mulch in winter to protect roots in colder climates",
  "common_weather_risks": "Black spot and mildew in high humidity",
  "protection_methods": "Use windbreaks and fungicide in wet seasons",
  "growth_stage": "vegetative"
}
