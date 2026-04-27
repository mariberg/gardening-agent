import boto3
import os
import json
import uuid
from datetime import datetime, timezone
from strands import Agent, tool
from strands_tools import http_request
from typing import Dict, Any, Optional

# Get configuration from environment variables (set by CloudFormation)
BEDROCK_REGION = os.environ.get('BEDROCK_REGION', 'eu-west-2')
USER_DATA_TABLE_NAME = os.environ.get('USER_DATA_TABLE_NAME', 'plant_database_users')
PLANT_DEFINITIONS_TABLE_NAME = os.environ.get('PLANT_DEFINITIONS_TABLE_NAME', 'garden_plants')

# Initialize DynamoDB resource with region from environment
dynamodb = boto3.resource('dynamodb', region_name=BEDROCK_REGION)

# Initialize table references
user_data_table = dynamodb.Table(USER_DATA_TABLE_NAME)
plant_definitions_table = dynamodb.Table(PLANT_DEFINITIONS_TABLE_NAME)

@tool
def dynamodb_lookup_user_data(user_id: str) -> Dict[str, Any]:
    """
    Looks up a user's latitude, longitude, and their list of plants in the user data DynamoDB table.
    This function is designed to be called by the LLM as a tool.

    Args:
        user_id (str): The ID of the user whose location and plant list is to be fetched.

    Returns:
        Dict[str, Any]: A dictionary containing 'latitude', 'longitude', and 'plants' (list of plant_ids)
                        on success, or an 'error' message if the user or location is not found.
    """
    try:
        response = user_data_table.get_item( # Using user_data_table here
            Key={'user_id': user_id} # Assuming 'user_id' is the primary key for user items
        )
        item = response.get('Item')

        if not item:
            print(f"DynamoDB Tool: No user item found for user_id '{user_id}'.")
            # Raise a specific exception that can be caught by error handlers
            raise ValueError(f"No user data found for user ID '{user_id}'. Please ensure it's registered.")

        latitude = item.get('latitude')
        longitude = item.get('longitude')
        plants = item.get('plants', []) # Get the list of plant IDs, default to empty list if not present

        if latitude is None or longitude is None:
            print(f"DynamoDB Tool: Latitude or longitude missing for user_id '{user_id}'. Item: {item}")
            return {'error': f"Location data is incomplete for user ID '{user_id}'."}

        print(f"DynamoDB Tool: Found user data for '{user_id}': lat={latitude}, lon={longitude}, plants={plants}")
        return {'latitude': float(latitude), 'longitude': float(longitude), 'plants': plants}

    except ValueError:
        # Re-raise ValueError (user not found) to be handled by main error handler
        raise
    except Exception as e:
        print(f"DynamoDB Tool Error (User Data): {e}")
        # For other database errors, raise with more context
        raise Exception(f"DynamoDB error while fetching user data for '{user_id}': {str(e)}")

@tool
def dynamodb_lookup_plant_data(plant_id: str) -> Dict[str, Any]:
    """
    Looks up detailed information for a single plant from the **plant definitions DynamoDB table**.
    This function is designed to be called by the LLM as a tool.

    Args:
        plant_id (str): The ID of the plant to fetch.

    Returns:
        Dict[str, Any]: A dictionary containing all attributes for the plant on success,
                        or an 'error' message if the plant is not found.
    """
    try:
        print(f"DynamoDB Tool: Attempting to fetch plant data for plant_id: {plant_id} from {PLANT_DEFINITIONS_TABLE_NAME}")
        response = plant_definitions_table.get_item( 
            Key={'plant_id': plant_id} 
        )
        print(f"DynamoDB Tool: Plant data query executed. Response: {response}")
        item = response.get('Item')
        print(f"DynamoDB Tool: Plant data result: {item}")

        if not item:
            print(f"DynamoDB Tool: No plant item found for plant_id '{plant_id}'.")
            return {'error': f"No plant data found for plant ID '{plant_id}'."}

        print(f"DynamoDB Tool: Found plant data for '{plant_id}': {item.get('common_name', 'N/A')}")
        return item # Return the full item with all plant attributes

    except Exception as e:
        print(f"DynamoDB Tool Error (Plant Data): {e}")
        return {'error': f"A database error occurred while fetching plant data for '{plant_id}': {str(e)}"}


WEATHER_SYSTEM_PROMPT = """You are a highly knowledgeable **Gardening Weather Advisor** with HTTP and database lookup capabilities. Your goal is to provide **tailored weather-related advice for a user's specific plants** based on current and forecast weather conditions.

**Here's your comprehensive workflow:**

1.  **Understand User's Request:**
    * If the user provides a `user_id` (e.g., "Give me plant advice for user_id testuser1"), you MUST immediately use the `dynamodb_lookup_user_data` tool to get their registered `latitude`, `longitude`, and their `plants` list (a list of plant IDs). This is your first and mandatory step.
    * If the user directly provides `latitude` and `longitude` AND a list of specific plant IDs (e.g., "What advice for plant_id 'rose_1', 'sunflower_2' at lat 52.52, lon 13.41?"), skip the initial user data lookup and proceed to step 2 with the provided coordinates and plant IDs.

2.  **Fetch User Data and Plant IDs (if `user_id` provided):**
    * Use the `dynamodb_lookup_user_data` tool, passing the `user_id` as the argument.
    * **Example tool call:** `dynamodb_lookup_user_data(user_id='testuser1')`
    * Carefully process the output of this tool. If it contains an 'error' key, inform the user about the error and terminate.
    * If the user has no plants registered (the `plants` list is empty), inform them and terminate.

3.  **Fetch Detailed Plant Information:**
    * For each `plant_id` obtained from the user data (or provided directly), you must use the `dynamodb_lookup_plant_data` tool to get its specific requirements.
    * **Crucial:** You must call `dynamodb_lookup_plant_data` for *each individual plant ID* in the list. Collect all the detailed plant dictionaries.
    * **Example tool call (for each plant):** `dynamodb_lookup_plant_data(plant_id='rose_1')`
    * If any plant lookup fails (returns an 'error' key), note it but continue fetching other plants.

4.  **Retrieve Current and Hourly Weather Data:**
    * Once you have the latitude and longitude (from user data or direct input), use the `http_request` tool to get weather from the **Open-Meteo API**.
    * The API endpoint is: `https://api.open-meteo.com/v1/forecast`
    * Make an HTTP GET request with the following query parameters:
        * `latitude={latitude}`
        * `longitude={longitude}`
        * `current=temperature_2m,wind_speed_10m,relative_humidity_2m`
        * `hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,temperature_80m`
    * **Example tool call:** `http_request(method='GET', url='https://api.open-meteo.com/v1/forecast?latitude=XX.XX&longitude=YY.YY&current=temperature_2m,wind_speed_10m,relative_humidity_2m&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation,temperature_80m')`
    * Process the weather API's JSON response.

5.  **Generate Tailored Weather Advice for Each Plant:**
    * For *each plant* you have detailed information for, compare the **current weather** and **hourly forecast** against the plant's specific requirements (min/max temp, ideal temp range, frost tolerance, sunlight, watering frequency, soil moisture, rainfall tolerance, humidity, wind tolerance, special notes, common risks, protection methods, growing/dormant season, frost dates).
    * **Only provide advice or mention conditions that require attention, mitigation, or action.** Do not explicitly state when conditions are ideal or "no action is needed" unless specifically asked or if it's highly noteworthy.
    * **Structure your advice clearly, addressing each plant individually.** Use bullet points for easy readability if a plant has multiple points of advice.
    * **Focus on actionable advice:**
        * Is the current/forecasted temperature too hot/cold? Suggest shelter, frost protection.
        * Is humidity ideal, too high, or too low? Advise misting or improving air circulation.
        * Is wind speed too high? Suggest staking or moving to a sheltered spot.
        * Is there expected precipitation? Advise on watering needs (or lack thereof).
        * Check sunlight hours against requirements.
        * Consider `growing_season`, `dormant_season`, and frost dates for planting/protection advice.
        * Mention any `common_weather_risks` that apply based on current/forecasted weather.
        * Refer to `protection_methods` if a risk is identified.
    * If a plant's conditions are *perfectly* within its ideal ranges for all factors and no risks are present, you can simply state, "Conditions are currently ideal for your [Plant Common Name]." but avoid listing every single perfect metric.

**Response Format Requirements:**
You must structure your response as a JSON object with exactly two attributes:
```json
{
    "details": {
        // Detailed advice for each plant, organized by plant name
        "Plant Name 1": "Specific advice for this plant...",
        "Plant Name 2": "Specific advice for this plant..."
    },
    "summary": "A concise summary of the overall advice and current conditions."
}
```

**Guidelines for the response format:**
- The "details" object should contain entries for each plant, with the plant's common name as the key and detailed advice as the value.
- For each plant, provide clear, concise, actionable advice focusing on conditions that require action or highlight potential issues.
- The "summary" should be a brief overview that captures the most important points from the detailed advice.
- Handle all errors gracefully within this JSON structure.
- Maintain a helpful and knowledgeable tone throughout.
"""


def is_api_gateway_event(event: Dict[str, Any]) -> bool:
    """
    Detect if the event is from API Gateway by checking for API Gateway-specific fields.
    """
    return (
        'httpMethod' in event and 
        'path' in event and 
        'headers' in event and
        'body' in event
    )


def parse_api_gateway_request(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Parse API Gateway proxy event to extract request data.
    """
    try:
        # Parse the body if it exists and is a string
        body = event.get('body')
        if body and isinstance(body, str):
            request_data = json.loads(body)
        elif body and isinstance(body, dict):
            request_data = body
        else:
            request_data = {}
        
        # Extract headers (case-insensitive)
        headers = event.get('headers', {})
        
        # Extract query parameters
        query_params = event.get('queryStringParameters') or {}
        
        return {
            'request_data': request_data,
            'headers': headers,
            'query_params': query_params,
            'http_method': event.get('httpMethod'),
            'path': event.get('path')
        }
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in request body: {str(e)}")


def create_api_gateway_response(
    status_code: int, 
    body: Dict[str, Any] = None, 
    error_message: str = None,
    user_id: str = None,
    weather_conditions: Dict[str, Any] = None,
    request_id: str = None
) -> Dict[str, Any]:
    """
    Create a properly formatted API Gateway response with CORS headers.
    Enhanced to include user_id, timestamp, weather conditions, and request tracking.
    """
    timestamp = datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')
    
    if error_message:
        # Error response format
        response_body = {
            "statusCode": status_code,
            "error": get_error_type_from_status(status_code),
            "message": error_message,
            "request_id": request_id or str(uuid.uuid4()),
            "timestamp": timestamp
        }
        if user_id:
            response_body["user_id"] = user_id
    else:
        # Success response format
        response_body = {
            "statusCode": status_code,
            "advice": body.get("summary", "") if body else "",
            "details": body.get("details", {}) if body else {},
            "timestamp": timestamp
        }
        if user_id:
            response_body["user_id"] = user_id
        if weather_conditions:
            response_body["weather_conditions"] = weather_conditions
    
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "POST,OPTIONS"
        },
        "body": json.dumps(response_body)
    }


def get_error_type_from_status(status_code: int) -> str:
    """
    Map HTTP status codes to error types for consistent error responses.
    """
    error_types = {
        400: "Bad Request",
        404: "Not Found", 
        500: "Internal Server Error",
        503: "Service Unavailable"
    }
    return error_types.get(status_code, "Unknown Error")


def validate_user_id(user_id: Any) -> tuple[bool, str]:
    """
    Validate user_id format and content.
    
    Args:
        user_id: The user_id value to validate
        
    Returns:
        tuple: (is_valid: bool, error_message: str)
    """
    if user_id is None:
        return False, "'user_id' field is required in the request body."
    
    if not isinstance(user_id, str):
        return False, "'user_id' must be a string."
    
    if not user_id.strip():
        return False, "'user_id' cannot be empty or contain only whitespace."
    
    # Check for basic format requirements (alphanumeric, underscore, hyphen allowed)
    import re
    if not re.match(r'^[a-zA-Z0-9_-]+$', user_id.strip()):
        return False, "'user_id' contains invalid characters. Only letters, numbers, underscores, and hyphens are allowed."
    
    # Check length constraints
    if len(user_id.strip()) < 1:
        return False, "'user_id' must be at least 1 character long."
    
    if len(user_id.strip()) > 50:
        return False, "'user_id' must be 50 characters or less."
    
    return True, ""


def handle_database_error(error: Exception, user_id: str = None) -> tuple[int, str]:
    """
    Handle database-related errors and return appropriate status code and message.
    
    Args:
        error: The exception that occurred
        user_id: The user_id that was being processed
        
    Returns:
        tuple: (status_code: int, error_message: str)
    """
    error_str = str(error).lower()
    
    # Check for user not found errors
    if "no user data found" in error_str or "no user item found" in error_str:
        return 404, f"User not found: No user profile found for user_id: {user_id}"
    
    # Check for DynamoDB specific errors
    if "resourcenotfoundexception" in error_str:
        return 404, f"User not found: No user profile found for user_id: {user_id}"
    
    if "accessdeniedexception" in error_str or "unauthorizedoperation" in error_str:
        return 500, "Database access error. Please contact support."
    
    if "throttlingexception" in error_str or "provisionedthroughputexceeded" in error_str:
        return 503, "Service temporarily unavailable due to high demand. Please try again later."
    
    if "validationexception" in error_str:
        return 400, f"Invalid user_id format: {user_id}"
    
    # Generic database error
    return 500, "A database error occurred while processing your request."


def handle_ai_service_error(error: Exception) -> tuple[int, str]:
    """
    Handle AI service (Bedrock) related errors and return appropriate status code and message.
    
    Args:
        error: The exception that occurred
        
    Returns:
        tuple: (status_code: int, error_message: str)
    """
    error_str = str(error).lower()
    
    # Check for Bedrock specific errors
    if "bedrock" in error_str or "nova" in error_str:
        if "throttling" in error_str or "rate" in error_str:
            return 503, "AI service temporarily unavailable due to high demand. Please try again later."
        elif "access" in error_str or "unauthorized" in error_str:
            return 500, "AI service access error. Please contact support."
        else:
            return 503, "AI service temporarily unavailable. Please try again later."
    
    # Check for weather service errors
    if "weather" in error_str or "open-meteo" in error_str or "http_request" in error_str:
        return 503, "Weather service temporarily unavailable. Please try again later."
    
    # Generic service error
    return 503, "External service temporarily unavailable. Please try again later."


def extract_weather_conditions_from_response(agent_response: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract weather conditions from the agent response for frontend display.
    This parses the agent's detailed response to find weather information.
    """
    try:
        # Look for weather information in the summary or details
        summary = agent_response.get("summary", "")
        details = agent_response.get("details", {})
        
        # Initialize weather conditions structure
        weather_conditions = {}
        
        # Try to extract temperature, humidity, and general conditions from the response text
        # This is a simple extraction - in a production system, you might want to 
        # store weather data separately during the agent processing
        
        # Look for temperature mentions
        import re
        temp_match = re.search(r'(\d+)°?[CF]?', summary + " " + str(details))
        if temp_match:
            weather_conditions["temperature"] = int(temp_match.group(1))
        
        # Look for humidity mentions
        humidity_match = re.search(r'(\d+)%.*humidity|humidity.*(\d+)%', summary + " " + str(details), re.IGNORECASE)
        if humidity_match:
            humidity_value = humidity_match.group(1) or humidity_match.group(2)
            weather_conditions["humidity"] = int(humidity_value)
        
        # Look for general weather conditions (order matters - more specific first)
        weather_keywords = ["partly cloudy", "overcast", "sunny", "cloudy", "rainy", "windy", "clear"]
        text_to_search = (summary + " " + str(details)).lower()
        for keyword in weather_keywords:
            if keyword in text_to_search:
                weather_conditions["condition"] = keyword
                break
        
        # Only return weather conditions if we found at least one piece of weather data
        return weather_conditions if weather_conditions else None
        
    except Exception as e:
        print(f"Error extracting weather conditions: {e}")
        return None


def lambda_handler(event: Dict[str, Any], _context) -> Dict[str, Any]:
    """
    Lambda handler that supports both direct invocation and API Gateway proxy events.
    Enhanced with improved response formatting including user_id, timestamp, and weather conditions.
    """
    request_id = str(uuid.uuid4())
    user_id = None
    
    try:
        # Check if this is an API Gateway event
        if is_api_gateway_event(event):
            print(f"Processing API Gateway event - Request ID: {request_id}")
            
            # Handle OPTIONS request for CORS preflight
            if event.get('httpMethod') == 'OPTIONS':
                return create_api_gateway_response(200, {}, request_id=request_id)
            
            # Parse API Gateway request
            try:
                parsed_request = parse_api_gateway_request(event)
                request_data = parsed_request['request_data']
                
                # Extract user_id from request data
                user_id = request_data.get('user_id')
                
                # Validate user_id using enhanced validation
                is_valid, validation_error = validate_user_id(user_id)
                if not is_valid:
                    return create_api_gateway_response(
                        400, 
                        error_message=validation_error,
                        user_id=user_id if isinstance(user_id, str) else None,
                        request_id=request_id
                    )
                
                # Clean the user_id (strip whitespace)
                user_id = user_id.strip()
                
                # Construct prompt from user_id - this will trigger the dynamodb_lookup_user_data tool
                user_prompt = f"Give me plant advice for user_id {user_id}"
                
            except ValueError as e:
                return create_api_gateway_response(
                    400, 
                    error_message=f"Invalid request format: {str(e)}",
                    user_id=user_id,
                    request_id=request_id
                )
            except Exception as e:
                return create_api_gateway_response(
                    500, 
                    error_message=f"Failed to parse request: {str(e)}",
                    user_id=user_id,
                    request_id=request_id
                )
        
        else:
            print(f"Processing direct Lambda invocation - Request ID: {request_id}")
            # Direct Lambda invocation - support both user_id and prompt formats
            user_id = event.get('user_id')
            user_prompt = event.get('prompt')
            
            if user_id:
                # Validate user_id format using enhanced validation
                is_valid, validation_error = validate_user_id(user_id)
                if not is_valid:
                    return {
                        "details": {},
                        "summary": f"Error: {validation_error}",
                        "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
                        "user_id": user_id if isinstance(user_id, str) else None,
                        "request_id": request_id
                    }
                # Clean the user_id (strip whitespace)
                user_id = user_id.strip()
                # Construct prompt from user_id - this will trigger the dynamodb_lookup_user_data tool
                user_prompt = f"Give me plant advice for user_id {user_id}"
            elif user_prompt:
                # Use existing prompt (backward compatibility)
                pass
            else:
                return {
                    "details": {},
                    "summary": "Error: Either 'user_id' or 'prompt' must be provided in the event.",
                    "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
                    "request_id": request_id
                }

        # Initialize the agent with all necessary tools
        plant_weather_agent = Agent(
            system_prompt=WEATHER_SYSTEM_PROMPT,
            tools=[http_request, dynamodb_lookup_user_data, dynamodb_lookup_plant_data], 
            model="amazon.nova-lite-v1:0",
            region=BEDROCK_REGION,
        )

        # Process the request
        print(f"Processing agent request for user_id: {user_id}")
        response = plant_weather_agent(user_prompt)
        
        # Extract weather conditions from the agent response
        weather_conditions = extract_weather_conditions_from_response(response)
        
        # Return appropriate response format
        if is_api_gateway_event(event):
            return create_api_gateway_response(
                200, 
                response, 
                user_id=user_id,
                weather_conditions=weather_conditions,
                request_id=request_id
            )
        else:
            # Direct invocation - return enhanced response format
            enhanced_response = {
                "advice": response.get("summary", ""),
                "details": response.get("details", {}),
                "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
                "request_id": request_id
            }
            if user_id:
                enhanced_response["user_id"] = user_id
            if weather_conditions:
                enhanced_response["weather_conditions"] = weather_conditions
            return enhanced_response
            
    except Exception as e:
        print(f"Agent processing error: {e}")
        
        # Determine error type and appropriate response
        error_str = str(e).lower()
        
        # Check for database-related errors first
        if any(keyword in error_str for keyword in ["dynamodb", "database", "user data", "user item"]):
            status_code, error_message = handle_database_error(e, user_id)
        # Check for AI service or weather service errors
        elif any(keyword in error_str for keyword in ["bedrock", "nova", "weather", "http_request", "service"]):
            status_code, error_message = handle_ai_service_error(e)
        else:
            # Generic internal server error
            status_code = 500
            error_message = "An internal error occurred while processing your request."
        
        # Log detailed error for debugging (but don't expose to user)
        print(f"Detailed error for request {request_id}: {str(e)}")
        
        if is_api_gateway_event(event):
            return create_api_gateway_response(
                status_code, 
                error_message=error_message,
                user_id=user_id,
                request_id=request_id
            )
        else:
            return {
                "details": {},
                "summary": error_message,
                "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
                "user_id": user_id,
                "request_id": request_id
            }