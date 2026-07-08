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
```

## Work in Progress

The following components are currently under development and not yet fully tested:

- `frontend/` - Web-based user interface (vanilla HTML/CSS/JavaScript)
- `scripts/` - Deployment and utility scripts  
- `tests/` - Test suite for validation and integration testing


---

## Authentication

The `POST /advice` endpoint is protected by an Amazon Cognito JWT authorizer. Every request must include a valid Access Token in the `Authorization` header. Unauthenticated requests receive a `401` response before the Lambda function is ever invoked. `OPTIONS` preflight requests remain public.

Get the User Pool ID and Client ID from the CloudFormation stack outputs:

| Output key | Used for |
|---|---|
| `CognitoUserPoolId` | `UserPoolId` in the SDK config |
| `CognitoUserPoolClientId` | `ClientId` in the SDK config |

---

### Sign-In Flow

Use the `amazon-cognito-identity-js` SDK (or AWS Amplify Auth). The `USER_SRP_AUTH` flow is preferred because the password is never sent in plaintext; `USER_PASSWORD_AUTH` is acceptable for local testing.

```javascript
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const poolData = {
  UserPoolId: process.env.REACT_APP_USER_POOL_ID,        // from CloudFormation output CognitoUserPoolId
  ClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,   // from CloudFormation output CognitoUserPoolClientId
};
const userPool = new CognitoUserPool(poolData);

function signIn(email, password) {
  const user = new CognitoUser({ Username: email, Pool: userPool });
  const authDetails = new AuthenticationDetails({ Username: email, Password: password });

  return new Promise((resolve, reject) => {
    user.authenticateUser(authDetails, {
      onSuccess(session) {
        // Store tokens in memory (avoid localStorage for security)
        const accessToken = session.getAccessToken().getJwtToken();
        const idToken = session.getIdToken().getJwtToken();
        const refreshToken = session.getRefreshToken().getToken();
        tokenStore.set({
          accessToken,
          idToken,
          refreshToken,
          expiresAt: session.getAccessToken().getExpiration(),
        });
        resolve(session);
      },
      onFailure(err) {
        // Display error to user — do NOT store tokens
        reject(err);
      },
      newPasswordRequired(userAttributes) {
        // FORCE_CHANGE_PASSWORD — see section below
        user.completeNewPasswordChallenge(newPassword, {}, this);
      },
    });
  });
}
```

---

### Calling the API

Send the **Access Token** (not the ID Token) in the `Authorization` header. Refresh it proactively when it is within 60 seconds of expiry, and retry once on a `401` in case the token expired between the proactive check and the actual call.

```javascript
async function callAdviceEndpoint(body) {
  let { accessToken, expiresAt } = tokenStore.get();

  // Proactive refresh: renew if token expires within 60 seconds
  if (Date.now() / 1000 > expiresAt - 60) {
    accessToken = await refreshTokens();
  }

  const response = await fetch('/advice', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': accessToken,   // Access Token only — not the ID Token
    },
    body: JSON.stringify(body),
  });

  // Retry-once on 401 (token may have expired between the proactive check and this call)
  if (response.status === 401) {
    try {
      accessToken = await refreshTokens();
    } catch {
      signOut();   // Refresh token expired — force re-login
      throw new Error('Session expired. Please sign in again.');
    }
    return fetch('/advice', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': accessToken },
      body: JSON.stringify(body),
    });
  }

  return response;
}

async function refreshTokens() {
  const { refreshToken } = tokenStore.get();
  // Use the Cognito SDK RefreshToken flow; throws if the refresh token is expired or invalid
  const newSession = await cognitoUser.refreshSession(refreshToken);
  const newAccessToken = newSession.getAccessToken().getJwtToken();
  tokenStore.update({
    accessToken: newAccessToken,
    expiresAt: newSession.getAccessToken().getExpiration(),
  });
  return newAccessToken;
}
```

---

### FORCE_CHANGE_PASSWORD Handling

When a user is created manually in the AWS Console their account starts in the `FORCE_CHANGE_PASSWORD` state. Their first sign-in triggers the `newPasswordRequired` callback instead of `onSuccess`. The frontend must:

1. Show a "Set your permanent password" dialog.
2. Collect a new password that satisfies the pool policy (≥8 characters, uppercase, lowercase, number, symbol).
3. Call `user.completeNewPasswordChallenge(newPassword, {}, callbacks)`.
4. If Cognito rejects the password (policy violation), show the error and let the user try again — the account stays in `FORCE_CHANGE_PASSWORD`.
5. Once the challenge succeeds, Cognito issues `AccessToken`, `IdToken`, and `RefreshToken` and the normal sign-in flow resumes.

Do not store tokens or consider the user authenticated until `completeNewPasswordChallenge` succeeds.

---

### Manual User Creation (AWS Console)

These steps let an administrator onboard users before self-service sign-up is available.

#### Step 1 — Open the User Pool

1. Sign into the AWS Console.
2. Navigate to **Cognito → User Pools**.
3. Click the user pool named `gardening-agent-user-pool-<env>`.

#### Step 2 — Create the User

1. Select the **Users** tab → **Create user**.
2. **Invitation message**: choose *Send an email invitation* if SES is configured (optional).
3. **Username**: enter the user's email address (the pool uses email as the username).
4. **Temporary password**: enter a password that meets the pool policy (≥8 chars, upper, lower, number, symbol). The user is forced to change it on first login.
5. **Email address**: confirm the address and tick **Mark email address as verified** so the user does not need a separate verification step.
6. Click **Create user**. The user appears with status `FORCE_CHANGE_PASSWORD`.

#### Step 3 — Note the Cognito `sub` UUID

On the user's detail page, find **Attributes → sub**. Copy this UUID — you need it for the DynamoDB record in Step 4.

#### Step 4 — Create the UserProfiles Record

Create a record in the `UserProfiles-<env>` DynamoDB table that links the Cognito `sub` to a garden. You can do this via the DynamoDB Console (**Explore items → Create item**) or with the AWS CLI:

```bash
aws dynamodb put-item \
  --table-name UserProfiles-dev \
  --item '{
    "user_id":     {"S": "alice"},
    "cognito_sub": {"S": "<sub-uuid>"},
    "garden_id":   {"S": "garden_001"},
    "display_name":{"S": "Alice"},
    "email":       {"S": "alice@example.com"},
    "latitude":    {"S": "51.5074"},
    "longitude":   {"S": "-0.1278"},
    "created_at":  {"S": "2026-01-15T10:00:00Z"}
  }'
```

The JSON record shape:

```json
{
  "user_id": "alice",
  "cognito_sub": "<sub-uuid>",
  "garden_id": "garden_001",
  "display_name": "Alice",
  "email": "alice@example.com",
  "latitude": "51.5074",
  "longitude": "-0.1278",
  "created_at": "2026-01-15T10:00:00Z"
}
```

`user_id` can be any human-readable key or the `sub` UUID itself. `cognito_sub` must match the value from Step 3 exactly.

#### Step 5 — Verify Access

Have the user sign in with their email and temporary password. After they set a permanent password through the `FORCE_CHANGE_PASSWORD` dialog, call `POST /advice` with the resulting `AccessToken`. The Lambda resolves the `UserProfiles` record via `cognito_sub`, finds `garden_id`, and returns advice for that garden.
