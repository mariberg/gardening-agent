# Gardening Agent

The Gardening Agent is an AI-powered assistant that provides personalized plant care advice based on your specific garden plants and current weather conditions. Simply provide your user ID, and the agent automatically looks up what plants you're growing, checks the local weather forecast, and generates tailored recommendations for each plant in your garden.

This gardening agent has been built using the AWS Strands Agents SDK. The agent has access to the Amazon Nova Lite AI model and utilizes three tools. The first tool is a Strands built-in tool 'http_request', which the agent can utilize to fetch weather data. In addition there are two custom tools that enable the agent to fetch data from DynamoDB. The agent is able to fetch user data, which contains a list of garden plants the user has. The agent is also able to fetch plant-specific details from a second DynamoDB table. Based on this data, the AI model is able to create tailored weather-related advice for a user's specific plants.

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

The project includes Infrastructure as Code (IaC) using AWS CloudFormation. 

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

### Prerequisites
- AWS CLI configured with appropriate permissions
- Access to Amazon Bedrock (Nova Lite model) in your AWS account


## API Gateway Integration

The Lambda function supports HTTP API access through API Gateway integration. 

### API Request Format

When calling through API Gateway, send a POST request with JSON body containing only the user ID:

```json
{
  "user_id": "test_user"
}
```

### API Response Format

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

### Example API Usage

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

## Work in Progress

The following components are currently under development and not yet fully tested:

- `frontend/` - Web-based user interface (vanilla HTML/CSS/JavaScript)
- `scripts/` - Deployment and utility scripts  
- `tests/` - Test suite for validation and integration testing
