#!/usr/bin/env python3
"""
Test script to verify the enhanced response formatting for the simplified API.
Tests the new response structure with user_id, timestamp, and weather conditions.
"""

import json
import uuid
import re
from datetime import datetime
from typing import Dict, Any, Optional

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
    timestamp = datetime.utcnow().isoformat() + "Z"
    
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

def test_api_gateway_success_response():
    """Test API Gateway success response formatting"""
    print("Testing API Gateway success response formatting...")
    
    # Mock agent response
    mock_agent_response = {
        "details": {
            "Tomato": "Water regularly and watch for temperature drops",
            "Basil": "Protect from wind and ensure good drainage"
        },
        "summary": "Current temperature is 22°C with 65% humidity. Partly cloudy conditions expected."
    }
    
    response = create_api_gateway_response(
        200,
        mock_agent_response,
        user_id="test_user_123",
        weather_conditions={"temperature": 22, "humidity": 65, "condition": "partly_cloudy"},
        request_id="test-request-123"
    )
    
    # Parse the response body
    body = json.loads(response["body"])
    
    # Verify response structure
    assert response["statusCode"] == 200
    assert "timestamp" in body
    assert body["user_id"] == "test_user_123"
    assert body["advice"] == mock_agent_response["summary"]
    assert body["details"] == mock_agent_response["details"]
    assert body["weather_conditions"]["temperature"] == 22
    assert body["weather_conditions"]["humidity"] == 65
    assert body["weather_conditions"]["condition"] == "partly_cloudy"
    
    print("✓ API Gateway success response formatting test passed")

def test_api_gateway_error_response():
    """Test API Gateway error response formatting"""
    print("Testing API Gateway error response formatting...")
    
    response = create_api_gateway_response(
        404,
        error_message="No user profile found for user_id: test_user_123",
        user_id="test_user_123",
        request_id="test-request-456"
    )
    
    # Parse the response body
    body = json.loads(response["body"])
    
    # Verify error response structure
    assert response["statusCode"] == 404
    assert body["statusCode"] == 404
    assert body["error"] == "Not Found"
    assert body["message"] == "No user profile found for user_id: test_user_123"
    assert body["user_id"] == "test_user_123"
    assert body["request_id"] == "test-request-456"
    assert "timestamp" in body
    
    print("✓ API Gateway error response formatting test passed")

def test_weather_extraction():
    """Test weather conditions extraction from agent response"""
    print("Testing weather conditions extraction...")
    
    # Mock agent response with weather information
    mock_response = {
        "details": {
            "Rose": "Current temperature is 18°C, which is ideal for roses"
        },
        "summary": "Today's weather shows 18°C temperature with 70% humidity. Partly cloudy conditions are perfect for your garden."
    }
    
    weather_conditions = extract_weather_conditions_from_response(mock_response)
    
    # Debug output
    print(f"Extracted weather conditions: {weather_conditions}")
    
    # Verify weather extraction
    assert weather_conditions is not None, "Weather conditions should not be None"
    assert "temperature" in weather_conditions, f"Temperature not found in {weather_conditions}"
    assert weather_conditions["temperature"] == 18, f"Expected temperature 18, got {weather_conditions.get('temperature')}"
    assert "humidity" in weather_conditions, f"Humidity not found in {weather_conditions}"
    assert weather_conditions["humidity"] == 70, f"Expected humidity 70, got {weather_conditions.get('humidity')}"
    assert "condition" in weather_conditions, f"Condition not found in {weather_conditions}"
    assert weather_conditions["condition"] == "partly cloudy", f"Expected 'partly cloudy', got {weather_conditions.get('condition')}"
    
    print("✓ Weather conditions extraction test passed")

def test_cors_headers():
    """Test that CORS headers are properly included"""
    print("Testing CORS headers...")
    
    response = create_api_gateway_response(200, {})
    
    headers = response["headers"]
    assert headers["Access-Control-Allow-Origin"] == "*"
    assert "Content-Type" in headers
    assert "Access-Control-Allow-Headers" in headers
    assert "Access-Control-Allow-Methods" in headers
    
    print("✓ CORS headers test passed")

def main():
    """Run all tests"""
    print("Running response formatting tests...\n")
    
    try:
        test_api_gateway_success_response()
        test_api_gateway_error_response()
        test_weather_extraction()
        test_cors_headers()
        
        print("\n✅ All response formatting tests passed!")
        return 0
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())