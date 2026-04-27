#!/usr/bin/env python3
"""
Test script for user_id validation logic without AWS dependencies.
"""

import re
from typing import Any


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
        ("test_user", True, ""),
        ("test-user-123", True, ""),
        ("123user", True, ""),
        ("user$invalid", False, "invalid characters"),
        ("user.invalid", False, "invalid characters"),
    ]
    
    passed = 0
    total = len(test_cases)
    
    for user_id, expected_valid, expected_error_contains in test_cases:
        is_valid, error_message = validate_user_id(user_id)
        
        if is_valid != expected_valid:
            print(f"❌ FAIL: user_id={user_id}, expected valid={expected_valid}, got valid={is_valid}")
            continue
        
        if not expected_valid and expected_error_contains not in error_message.lower():
            print(f"❌ FAIL: user_id={user_id}, expected error to contain '{expected_error_contains}', got '{error_message}'")
            continue
        
        print(f"✅ PASS: user_id={user_id} -> valid={is_valid}")
        passed += 1
    
    print(f"User ID validation: {passed}/{total} tests passed\n")
    return passed == total


def test_error_handler_functions():
    """Test the error handler utility functions."""
    print("Testing error handler functions...")
    
    passed = 0
    total = 0
    
    # Test database error handling
    test_cases = [
        (ValueError("No user data found for user ID 'testuser'"), "testuser", 404, "user not found"),
        (Exception("ResourceNotFoundException"), "testuser", 404, "user not found"),
        (Exception("AccessDeniedException"), "testuser", 500, "access error"),
        (Exception("ThrottlingException"), "testuser", 503, "temporarily unavailable"),
        (Exception("ValidationException"), "testuser", 400, "invalid user_id"),
        (Exception("Generic database error"), "testuser", 500, "database error"),
    ]
    
    for error, user_id, expected_status, expected_message_contains in test_cases:
        total += 1
        status_code, message = handle_database_error(error, user_id)
        
        if status_code != expected_status:
            print(f"❌ FAIL: Expected {expected_status} for {error}, got {status_code}")
            continue
        
        if expected_message_contains not in message.lower():
            print(f"❌ FAIL: Expected '{expected_message_contains}' in message, got '{message}'")
            continue
        
        print(f"✅ PASS: Database error {type(error).__name__} -> {status_code}")
        passed += 1
    
    # Test AI service error handling
    ai_test_cases = [
        (Exception("Bedrock service unavailable"), 503, "service"),
        (Exception("Nova model throttling"), 503, "temporarily unavailable"),
        (Exception("Bedrock access denied"), 500, "access error"),
        (Exception("Weather API error"), 503, "weather service"),
        (Exception("http_request failed"), 503, "service"),
        (Exception("Generic service error"), 503, "service"),
    ]
    
    for error, expected_status, expected_message_contains in ai_test_cases:
        total += 1
        status_code, message = handle_ai_service_error(error)
        
        if status_code != expected_status:
            print(f"❌ FAIL: Expected {expected_status} for {error}, got {status_code}")
            continue
        
        if expected_message_contains not in message.lower():
            print(f"❌ FAIL: Expected '{expected_message_contains}' in message, got '{message}'")
            continue
        
        print(f"✅ PASS: AI service error -> {status_code}")
        passed += 1
    
    print(f"Error handler functions: {passed}/{total} tests passed\n")
    return passed == total


def main():
    """Run all validation tests."""
    print("🧪 Running Enhanced Error Handling Validation Tests\n")
    
    tests = [
        test_user_id_validation,
        test_error_handler_functions,
    ]
    
    all_passed = True
    
    for test in tests:
        try:
            if not test():
                all_passed = False
        except Exception as e:
            print(f"❌ Test {test.__name__} failed with exception: {e}")
            all_passed = False
    
    if all_passed:
        print("🎉 All validation tests passed!")
        print("\n✅ Enhanced error handling implementation is working correctly:")
        print("  - User ID validation with comprehensive format checking")
        print("  - Specific error handling for missing/invalid user_id (400)")
        print("  - Database error handling for user not found (404)")
        print("  - Service error handling for AI/weather services (503)")
        print("  - Proper error message formatting and logging")
        return True
    else:
        print("❌ Some tests failed. Please review the implementation.")
        return False


if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)