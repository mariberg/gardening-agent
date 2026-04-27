#!/usr/bin/env python3
"""
Test script for enhanced error handling in the API simplification feature.
Tests various error scenarios for user_id validation and database errors.
"""

import json
import sys
import os

# Add src directory to path to import agent module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from agent import lambda_handler, validate_user_id, handle_database_error, handle_ai_service_error


def test_user_id_validation():
    """Test user_id validation function with various inputs."""
    print("Testing user_id validation...")
    
    test_cases = [
        # (input, expected_valid, expected_error_contains)
        (None, False, "required"),
        ("", False, "empty"),
        ("   ", False, "whitespace"),
        (123, False, "string"),
        ("valid_user", True, ""),
        ("user-123", True, ""),
        ("user@invalid", False, "invalid characters"),
        ("a" * 51, False, "50 characters"),
        ("user with spaces", False, "invalid characters"),
        ("user123", True, ""),
    ]
    
    for user_id, expected_valid, expected_error_contains in test_cases:
        is_valid, error_message = validate_user_id(user_id)
        
        if is_valid != expected_valid:
            print(f"❌ FAIL: user_id={user_id}, expected valid={expected_valid}, got valid={is_valid}")
            return False
        
        if not expected_valid and expected_error_contains not in error_message.lower():
            print(f"❌ FAIL: user_id={user_id}, expected error to contain '{expected_error_contains}', got '{error_message}'")
            return False
        
        print(f"✅ PASS: user_id={user_id} -> valid={is_valid}, error='{error_message}'")
    
    return True


def test_api_gateway_error_responses():
    """Test API Gateway error responses for various scenarios."""
    print("\nTesting API Gateway error responses...")
    
    # Test missing user_id
    event = {
        'httpMethod': 'POST',
        'path': '/advice',
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({})
    }
    
    response = lambda_handler(event, None)
    response_body = json.loads(response['body'])
    
    if response['statusCode'] != 400:
        print(f"❌ FAIL: Expected 400 for missing user_id, got {response['statusCode']}")
        return False
    
    if 'required' not in response_body['message'].lower():
        print(f"❌ FAIL: Expected 'required' in error message, got '{response_body['message']}'")
        return False
    
    print("✅ PASS: Missing user_id returns 400 with appropriate message")
    
    # Test invalid user_id format
    event['body'] = json.dumps({'user_id': 'user@invalid'})
    response = lambda_handler(event, None)
    response_body = json.loads(response['body'])
    
    if response['statusCode'] != 400:
        print(f"❌ FAIL: Expected 400 for invalid user_id, got {response['statusCode']}")
        return False
    
    if 'invalid characters' not in response_body['message'].lower():
        print(f"❌ FAIL: Expected 'invalid characters' in error message, got '{response_body['message']}'")
        return False
    
    print("✅ PASS: Invalid user_id format returns 400 with appropriate message")
    
    # Test empty user_id
    event['body'] = json.dumps({'user_id': ''})
    response = lambda_handler(event, None)
    response_body = json.loads(response['body'])
    
    if response['statusCode'] != 400:
        print(f"❌ FAIL: Expected 400 for empty user_id, got {response['statusCode']}")
        return False
    
    print("✅ PASS: Empty user_id returns 400 with appropriate message")
    
    return True


def test_direct_invocation_error_responses():
    """Test direct Lambda invocation error responses."""
    print("\nTesting direct invocation error responses...")
    
    # Test invalid user_id in direct invocation
    event = {'user_id': 'user@invalid'}
    response = lambda_handler(event, None)
    
    if 'invalid characters' not in response['summary'].lower():
        print(f"❌ FAIL: Expected 'invalid characters' in summary, got '{response['summary']}'")
        return False
    
    print("✅ PASS: Direct invocation with invalid user_id returns appropriate error")
    
    # Test missing user_id and prompt
    event = {}
    response = lambda_handler(event, None)
    
    if 'must be provided' not in response['summary'].lower():
        print(f"❌ FAIL: Expected 'must be provided' in summary, got '{response['summary']}'")
        return False
    
    print("✅ PASS: Direct invocation without user_id or prompt returns appropriate error")
    
    return True


def test_error_handler_functions():
    """Test the error handler utility functions."""
    print("\nTesting error handler functions...")
    
    # Test database error handling
    user_not_found_error = ValueError("No user data found for user ID 'testuser'")
    status_code, message = handle_database_error(user_not_found_error, "testuser")
    
    if status_code != 404:
        print(f"❌ FAIL: Expected 404 for user not found, got {status_code}")
        return False
    
    if "user not found" not in message.lower():
        print(f"❌ FAIL: Expected 'user not found' in message, got '{message}'")
        return False
    
    print("✅ PASS: Database error handler correctly identifies user not found (404)")
    
    # Test AI service error handling
    bedrock_error = Exception("Bedrock service unavailable")
    status_code, message = handle_ai_service_error(bedrock_error)
    
    if status_code != 503:
        print(f"❌ FAIL: Expected 503 for Bedrock error, got {status_code}")
        return False
    
    if "service" not in message.lower():
        print(f"❌ FAIL: Expected 'service' in message, got '{message}'")
        return False
    
    print("✅ PASS: AI service error handler correctly identifies service unavailable (503)")
    
    return True


def test_response_format_consistency():
    """Test that error responses maintain consistent format."""
    print("\nTesting response format consistency...")
    
    # Test API Gateway error response format
    event = {
        'httpMethod': 'POST',
        'path': '/advice',
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'user_id': ''})
    }
    
    response = lambda_handler(event, None)
    response_body = json.loads(response['body'])
    
    required_fields = ['statusCode', 'error', 'message', 'request_id', 'timestamp']
    for field in required_fields:
        if field not in response_body:
            print(f"❌ FAIL: Missing required field '{field}' in error response")
            return False
    
    print("✅ PASS: API Gateway error response contains all required fields")
    
    # Test direct invocation error response format
    event = {'user_id': ''}
    response = lambda_handler(event, None)
    
    required_fields = ['details', 'summary', 'timestamp', 'request_id']
    for field in required_fields:
        if field not in response:
            print(f"❌ FAIL: Missing required field '{field}' in direct invocation error response")
            return False
    
    print("✅ PASS: Direct invocation error response contains all required fields")
    
    return True


def main():
    """Run all error handling tests."""
    print("🧪 Running Enhanced Error Handling Tests\n")
    
    tests = [
        test_user_id_validation,
        test_api_gateway_error_responses,
        test_direct_invocation_error_responses,
        test_error_handler_functions,
        test_response_format_consistency,
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
            else:
                print(f"❌ Test {test.__name__} failed")
        except Exception as e:
            print(f"❌ Test {test.__name__} failed with exception: {e}")
    
    print(f"\n📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All error handling tests passed!")
        return True
    else:
        print("❌ Some tests failed. Please review the implementation.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)