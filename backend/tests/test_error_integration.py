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
    """
    Test API Gateway auth enforcement without AWS dependencies.

    After the Cognito authorizer was wired to the POST /advice endpoint, the
    Lambda now derives identity exclusively from JWT claims injected by API
    Gateway — the request body user_id is ignored on the API Gateway path.

    Any API Gateway POST event that reaches the Lambda without valid Cognito
    authorizer claims is rejected with 401 (missing/invalid claims) before any
    body validation runs.
    """
    print("Testing API Gateway auth enforcement (Cognito claims required)...")

    with patch('boto3.resource'):
        from agent import lambda_handler

        # Event without Cognito authorizer claims → 401 (auth enforced before body validation)
        event_no_claims = {
            'httpMethod': 'POST',
            'path': '/advice',
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({}),
            'queryStringParameters': None,
            'requestContext': {},  # no authorizer claims
        }
        response = lambda_handler(event_no_claims, None)
        response_body = json.loads(response['body'])

        assert response['statusCode'] == 401, (
            f"Expected 401 for request without Cognito claims, got {response['statusCode']}"
        )
        assert 'error' in response_body, "Expected 'error' field in 401 response body"
        assert 'request_id' in response_body, "Missing request_id in response"
        print("✅ PASS: Request without Cognito claims returns 401")

        # Event with empty sub → 401
        event_empty_sub = {
            'httpMethod': 'POST',
            'path': '/advice',
            'headers': {'Content-Type': 'application/json', 'Authorization': 'tok'},
            'body': json.dumps({}),
            'queryStringParameters': None,
            'requestContext': {
                'authorizer': {
                    'claims': {'sub': '', 'email': 'user@example.com'},
                },
            },
        }
        response = lambda_handler(event_empty_sub, None)
        response_body = json.loads(response['body'])

        assert response['statusCode'] == 401, (
            f"Expected 401 for empty sub claim, got {response['statusCode']}"
        )
        print("✅ PASS: Empty sub claim returns 401")

        # OPTIONS preflight still returns 200 (no auth check)
        event_options = {
            'httpMethod': 'OPTIONS',
            'path': '/advice',
            'headers': {'Origin': 'https://example.com'},
            'body': None,
            'queryStringParameters': None,
            'requestContext': {},
        }
        response = lambda_handler(event_options, None)
        assert response['statusCode'] == 200, (
            f"Expected 200 for OPTIONS preflight, got {response['statusCode']}"
        )
        print("✅ PASS: OPTIONS preflight returns 200 (no auth check)")


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
        print("\n✅ Cognito auth enforcement verified:")
        print("  - ✅ Missing Cognito claims returns 401 (auth enforced at Lambda entry)")
        print("  - ✅ Empty sub claim returns 401")
        print("  - ✅ OPTIONS preflight bypasses auth, returns 200")
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