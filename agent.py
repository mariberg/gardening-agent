import boto3
from strands import Agent, tool
from strands_tools import http_request
from typing import Dict, Any

dynamodb = boto3.resource('dynamodb', region_name='eu-west-2') 

USER_DATA_TABLE_NAME = 'plant_database_users' # This table holds user_id, lat, lon, plants list
user_data_table = dynamodb.Table(USER_DATA_TABLE_NAME)

PLANT_DEFINITIONS_TABLE_NAME = 'garden_plants' # This table holds detailed plant characteristics (ideal temp range, wind tolerance, etc.)
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
            return {'error': f"No user data found for user ID '{user_id}'. Please ensure it's registered."}

        latitude = item.get('latitude')
        longitude = item.get('longitude')
        plants = item.get('plants', []) # Get the list of plant IDs, default to empty list if not present

        if latitude is None or longitude is None:
            print(f"DynamoDB Tool: Latitude or longitude missing for user_id '{user_id}'. Item: {item}")
            return {'error': f"Location data is incomplete for user ID '{user_id}'."}

        print(f"DynamoDB Tool: Found user data for '{user_id}': lat={latitude}, lon={longitude}, plants={plants}")
        return {'latitude': float(latitude), 'longitude': float(longitude), 'plants': plants}

    except Exception as e:
        print(f"DynamoDB Tool Error (User Data): {e}")
        return {'error': f"A database error occurred while fetching user data for '{user_id}': {str(e)}"}

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
    * If the user provides a `user_id` (e.g., "Give me plant advice for user_id testuser1"), your first step is to use the `dynamodb_lookup_user_data` tool to get their registered `latitude`, `longitude`, and their `plants` list (a list of plant IDs).
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


def lambda_handler(event: Dict[str, Any], _context) -> Dict[str, Any]:
    user_prompt = event.get('prompt')

    if not user_prompt:
        return {
            "details": {},
            "summary": "Error: No user prompt provided in the event. Please provide a user ID or coordinates and optional plant IDs."
        }

    # Initialize the agent with all necessary tools
    plant_weather_agent = Agent(
        system_prompt=WEATHER_SYSTEM_PROMPT,
        tools=[http_request, dynamodb_lookup_user_data, dynamodb_lookup_plant_data], 
        model="amazon.nova-lite-v1:0",
    )

    try:
        response = plant_weather_agent(user_prompt)
        # The response should already be in the correct JSON format as specified in the prompt
        return response
    except Exception as e:
        print(f"Agent processing error: {e}")
        return {
            "details": {},
            "summary": f"An internal error occurred while processing your request: {str(e)}"
        }