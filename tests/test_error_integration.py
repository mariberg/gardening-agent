#!/usr/bin/env python3
"""
Integration test for error handling without requiring actual AWS services.
Tests the Lambda handler with mocked dependencies.
"""

import json
import sys
import os
from unittest.mock import patch, MagicMock

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))


def test_api_gateway_validation_errors():
    """Test API Gateway validation errors without AWS dependencies."""
    print("Testing API Gateway validation errors...")
    
    # Mock boto3 and other AWS dependencies
    with patch('boto3.resource') as mock_boto3:
        # Import after mocking
        from agent import lambda_handler
        
        # Test missing user_id
        event = {
            'httpMethod': 'POST',
            'path': '/advice',
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({})
        }
        
        response = lambda_handler(event, None)
        response_body = json.loads(response['body'])
        
        assert response['statusCode'] == 400, f"Expected 400, got {response['statusCode']}"
        assert 'required' in response_body['message'].lower(), f"Expected 'required' in message: {response_body['message']}"
        assert 'request_id' in response_body, "Missing request_id in response"
        print("✅ PASS: Missing user_id returns 400")
        
        # Test invalid user_id format
        event['body'] = json.dumps({'user_id': 'user@invalid'})
        response = lambda_handler(event, None)
        response_body = json.loads(response['body'])
        
        assert response['statusCode'] == 400, f"Expected 400, got {response['statusCode']}"
        assert 'invalid characters' in response_body['message'].lower(), f"Expected 'invalid characters' in message: {response_body['message']}"
        print("✅ PASS: Invalid user_id format returns 400")
        
        # Test empty user_id
        event['body'] = json.dumps({'user_id': ''})
        response = lambda_handler(event, None)
        response_body = json.loads(response['body'])
        
        assert response['statusCode'] == 400, f"Expected 400, got {response['statusCode']}"
        assert 'empty' in response_body['message'].lower(), f"Expected 'empty' in message: {response_body['message']}"
        print("✅ PASS: Empty user_id returns 400")
        
        # Test non-string user_id
        event['body'] = json.dumps({'user_id': 123})
        response = lambda_handler(event, None)
        response_body = json.loads(response['body'])
        
        assert response['statusCode'] == 400, f"Expected 400, got {response['statusCode']}"
        assert 'string' in response_body['message'].lower(), f"Expected 'string' in message: {response_body['message']}"
        print("✅ PASS: Non-string user_id returns 400")


def test_direct_invocation_validation_errors():
    """Test direct invocation validation errors."""
    print("\nTesting direct invocation validation errors...")
    
    with patch('boto3.resource') as mock_boto3:
        from agent import lambda_handler
        
        # Test invalid user_id
        event = {'user_id': 'user@invalid'}
        response = lambda_handler(event, None)
        
        assert 'invalid characters' in response['summary'].lower(), f"Expected 'invalid characters' in summary: {response['summary']}"
        assert 'request_id' in response, "Missing request_id in response"
        print("✅ PASS: Direct invocation with invalid user_id returns error")
        
        # Test missing both user_id and prompt
        event = {}
        response = lambda_handler(event, None)
        
        assert 'must be provided' in response['summary'].lower(), f"Expected 'must be provided' in summary: {response['summary']}"
        print("✅ PASS: Direct invocation without user_id or prompt returns error")


def test_cors_headers():
    """Test that CORS headers are included in error responses."""
    print("\nTesting CORS headers in error responses...")
    
    with patch('boto3.resource') as mock_boto3:
        from agent import lambda_handler
        
        event = {
            'httpMethod': 'POST',
            'path': '/advice',
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({})
        }
        
        response = lambda_handler(event, None)
        
        required_headers = [
            'Access-Control-Allow-Origin',
            'Access-Control-Allow-Headers',
            'Access-Control-Allow-Methods',
            'Content-Type'
        ]
        
        for header in required_headers:
            assert header in response['headers'], f"Missing CORS header: {header}"
        
        assert response['headers']['Access-Control-Allow-Origin'] == '*', "CORS origin should be *"
        print("✅ PASS: CORS headers included in error responses")


def test_options_request():
    """Test OPTIONS request handling for CORS preflight."""
    print("\nTesting OPTIONS request handling...")
    
    with patch('boto3.resource') as mock_boto3:
        from agent import lambda_handler
        
        event = {
            'httpMethod': 'OPTIONS',
            'path': '/advice',
            'headers': {'Content-Type': 'application/json'},
            'body': None
        }
        
        response = lambda_handler(event, None)
        
        assert response['statusCode'] == 200, f"Expected 200 for OPTIONS, got {response['statusCode']}"
        assert 'Access-Control-Allow-Origin' in response['headers'], "Missing CORS headers in OPTIONS response"
        print("✅ PASS: OPTIONS request returns 200 with CORS headers")


def main():
    """Run all integration tests."""
    print("🧪 Running Error Handling Integration Tests\n")
    
    tests = [
        test_api_gateway_validation_errors,
        test_direct_invocation_validation_errors,
        test_cors_headers,
        test_options_request,
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            test()
            passed += 1
            print(f"✅ {test.__name__} passed")
        except Exception as e:
            print(f"❌ {test.__name__} failed: {e}")
    
    print(f"\n📊 Integration Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All integration tests passed!")
        print("\n✅ Task 4 implementation verified:")
        print("  - ✅ Missing user_id validation (400 Bad Request)")
        print("  - ✅ Invalid user_id format validation (400 Bad Request)")
        print("  - ✅ Enhanced error message formatting")
        print("  - ✅ Request ID tracking for debugging")
        print("  - ✅ CORS headers in all responses")
        print("  - ✅ Consistent error response structure")
        print("  - ✅ Both API Gateway and direct invocation support")
        return True
    else:
        print("❌ Some integration tests failed.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)