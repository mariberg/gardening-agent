"""
Tests for authentication functions in agent.py.

Feature: cognito-api-authentication
"""
import json
import sys
import os
import pytest
from unittest.mock import MagicMock

# ---------------------------------------------------------------------------
# Stub out heavy dependencies so agent.py can be imported without them
# ---------------------------------------------------------------------------
for _mod in ("strands", "strands_tools", "strands.agent", "strands.tools"):
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()

# Provide the @tool decorator as a no-op passthrough
import types
_strands_stub = sys.modules["strands"]
_strands_stub.tool = lambda f: f
_strands_stub.Agent = MagicMock()

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import pytest
from hypothesis import given, settings, assume, strategies as st

from agent import extract_user_identity, resolve_garden_id, AuthError


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_event(sub: str, body_user_id: str = None) -> dict:
    """Build a minimal API Gateway proxy event with the given sub claim and optional body user_id."""
    body = {}
    if body_user_id is not None:
        body["user_id"] = body_user_id

    return {
        "httpMethod": "POST",
        "path": "/advice",
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": sub,
                    "email": "user@example.com",
                }
            }
        },
    }


# ---------------------------------------------------------------------------
# Feature: cognito-api-authentication
# Property 1: Identity from sub, not body
# Validates: Requirements 2.1, 2.2, 2.3
# ---------------------------------------------------------------------------

@given(body_user_id=st.text(min_size=1), sub=st.uuids().map(str))
@settings(max_examples=100)
def test_identity_always_from_sub(body_user_id: str, sub: str):
    """
    **Validates: Requirements 2.1, 2.2, 2.3**

    Property 1: Identity comes exclusively from the sub claim, never from the request body.

    For any combination of an arbitrary user_id value in the request body and a valid sub UUID
    in the authorizer claims, the identity resolved by extract_user_identity must equal the sub
    claim value and must never equal the request-body user_id (when the two differ).
    """
    assume(body_user_id.strip() != sub)

    event = make_event(sub=sub, body_user_id=body_user_id)
    resolved_sub, _ = extract_user_identity(event)

    assert resolved_sub == sub
    assert resolved_sub != body_user_id.strip()


# ---------------------------------------------------------------------------
# Helper: MockTable for resolve_garden_id tests
# ---------------------------------------------------------------------------

class MockTable:
    """Simple mock for a DynamoDB Table that has a scan() method."""

    def __init__(self, items=None, raise_exception=None):
        self._items = items or []
        self._raise = raise_exception

    def scan(self, **kwargs):
        if self._raise:
            raise self._raise
        return {"Items": self._items}


# ---------------------------------------------------------------------------
# Unit tests for resolve_garden_id
# Requirements: 3.1, 3.4, 3.8
# ---------------------------------------------------------------------------

def test_resolve_garden_id_found_mapping_returns_user_id_and_garden_id():
    """Found mapping → returns (user_id, garden_id). Requirements: 3.1"""
    table = MockTable(items=[
        {"user_id": "test_user", "cognito_sub": "some-sub-uuid", "garden_id": "garden_001"}
    ])
    user_id, garden_id = resolve_garden_id("some-sub-uuid", table)
    assert user_id == "test_user"
    assert garden_id == "garden_001"


def test_resolve_garden_id_empty_items_raises_403():
    """No record (empty Items) → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
    table = MockTable(items=[])
    try:
        resolve_garden_id("missing-sub", table)
        assert False, "Expected AuthError to be raised"
    except AuthError as e:
        assert e.status_code == 403
        assert e.error_code == "no_garden_association"


def test_resolve_garden_id_record_missing_garden_id_raises_403():
    """Record with no garden_id field → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
    table = MockTable(items=[
        {"user_id": "test_user", "cognito_sub": "some-sub-uuid"}
        # no garden_id key at all
    ])
    try:
        resolve_garden_id("some-sub-uuid", table)
        assert False, "Expected AuthError to be raised"
    except AuthError as e:
        assert e.status_code == 403
        assert e.error_code == "no_garden_association"


def test_resolve_garden_id_record_with_empty_garden_id_raises_403():
    """Record with garden_id='' (falsy) → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
    table = MockTable(items=[
        {"user_id": "test_user", "cognito_sub": "some-sub-uuid", "garden_id": ""}
    ])
    try:
        resolve_garden_id("some-sub-uuid", table)
        assert False, "Expected AuthError to be raised"
    except AuthError as e:
        assert e.status_code == 403
        assert e.error_code == "no_garden_association"


def test_resolve_garden_id_dynamodb_exception_raises_500():
    """DynamoDB throws exception → raises AuthError(500, 'membership_lookup_failed'). Requirements: 3.8"""
    table = MockTable(raise_exception=RuntimeError("DynamoDB connection refused"))
    try:
        resolve_garden_id("some-sub-uuid", table)
        assert False, "Expected AuthError to be raised"
    except AuthError as e:
        assert e.status_code == 500
        assert e.error_code == "membership_lookup_failed"


# ---------------------------------------------------------------------------
# Unit tests for extract_user_identity
# Task 3.3 — Requirements: 2.1, 2.4, 2.5
# ---------------------------------------------------------------------------

def _make_event_with_claims(sub, email=None):
    """Build a minimal event with only the authorizer claims structure."""
    claims = {"sub": sub}
    if email is not None:
        claims["email"] = email
    return {
        "requestContext": {
            "authorizer": {
                "claims": claims
            }
        }
    }


# --- Happy path ---

def test_valid_claims_returns_sub_and_email():
    """Valid sub and email → returns (sub, email) tuple."""
    event = _make_event_with_claims(sub="abc-123-uuid", email="user@example.com")
    result = extract_user_identity(event)
    assert result == ("abc-123-uuid", "user@example.com")


def test_valid_claims_no_email_returns_none():
    """Valid sub with no email claim → email is None."""
    event = _make_event_with_claims(sub="abc-123-uuid")
    sub, email = extract_user_identity(event)
    assert sub == "abc-123-uuid"
    assert email is None


def test_sub_is_stripped_in_return():
    """sub with surrounding whitespace is stripped."""
    event = _make_event_with_claims(sub="  trimmed-uuid  ")
    sub, _ = extract_user_identity(event)
    assert sub == "trimmed-uuid"


# --- Missing structure → AuthError(401) ---

def test_missing_request_context_raises_401():
    """Missing requestContext → raises AuthError(401)."""
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity({})
    assert exc_info.value.status_code == 401


def test_missing_authorizer_key_raises_401():
    """requestContext present but no authorizer key → raises AuthError(401)."""
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity({"requestContext": {}})
    assert exc_info.value.status_code == 401


def test_missing_claims_key_raises_401():
    """authorizer present but no claims key → raises AuthError(401)."""
    event = {"requestContext": {"authorizer": {}}}
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401


def test_request_context_none_raises_401():
    """requestContext is None (TypeError path) → raises AuthError(401)."""
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity({"requestContext": None})
    assert exc_info.value.status_code == 401


# --- Invalid sub → AuthError(401) ---

def test_empty_sub_raises_401():
    """sub = "" → raises AuthError(401)."""
    event = _make_event_with_claims(sub="")
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401


def test_whitespace_only_sub_raises_401():
    """sub is whitespace-only → raises AuthError(401)."""
    event = _make_event_with_claims(sub="   ")
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401


def test_tab_whitespace_sub_raises_401():
    """sub is tab/newline-only → raises AuthError(401)."""
    event = _make_event_with_claims(sub="\t\n")
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401


def test_none_sub_value_raises_401():
    """claims dict present but sub value is None → raises AuthError(401)."""
    event = {
        "requestContext": {
            "authorizer": {
                "claims": {"sub": None}
            }
        }
    }
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401


def test_missing_sub_key_raises_401():
    """claims has no 'sub' key at all → raises AuthError(401)."""
    event = {
        "requestContext": {
            "authorizer": {
                "claims": {"email": "user@example.com"}
            }
        }
    }
    with pytest.raises(AuthError) as exc_info:
        extract_user_identity(event)
    assert exc_info.value.status_code == 401
