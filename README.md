## Gardening Agent

This gardening agent has been built using the AWS Strands Agents SDK. The Python code for the agent is located in the `src/agent.py` file and is deployed as an AWS Lambda function. The agent has access to the Amazon Nova Lite AI model and utilizes three tools. The first tool is a Strands built-in tool 'http_request', which the agent can utilize to fetch weather data. In addition there are two custom tools that enable the agent to fetch data from DynamoDB. The agent is able to fetch user data, which contains a list of garden plants the user has. The agent is also able to fetch plant-specific details from a second DynamoDB table. Based on this data, the AI model is able to create tailored weather-related advice for a user's specific plants.

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

**Note**: The Lambda function handler is configured as `src.agent.lambda_handler` to match the new project structure. Environment variables for table names and region are automatically set by CloudFormation.

#### Update Infrastructure
```bash
aws cloudformation update-stack \
  --stack-name gardening-agent-dev \
  --template-body file://cloudformation/infrastructure.yaml \
  --parameters file://cloudformation/parameters/dev.json \
  --capabilities CAPABILITY_NAMED_IAM
```

### Access to Bedrock

The Lambda function uses Amazon Nova Lite model and access to this model needs to be requested through the Bedrock console. 


## Infrastructure Components

The CloudFormation template creates the following AWS resources:

- **Lambda Function**: `gardening-agent-dev` with proper IAM permissions and environment variable configuration
- **IAM Role**: Execution role with DynamoDB and Bedrock access
- **DynamoDB Tables**: Two tables for user data and plant definitions
- **Environment Variables**: Automatically configured for:
  - `USER_DATA_TABLE_NAME`: DynamoDB table name for user data
  - `PLANT_DEFINITIONS_TABLE_NAME`: DynamoDB table name for plant definitions  
  - `BEDROCK_REGION`: AWS region for Bedrock model access

## Configuration

The Lambda function now uses environment variables for all configuration, making it environment-agnostic:

- **Table Names**: Dynamically configured via CloudFormation parameters
- **AWS Region**: Configurable for Bedrock access (defaults to `eu-west-2`)
- **Fallback Values**: Default values provided for local development

This approach ensures the same code can be deployed across different environments (dev, staging, prod) without modification.

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
