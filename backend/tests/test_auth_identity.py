"""
Tests for extract_user_identity in agent.py.

Feature: cognito-api-authentication
Tasks: 3.3 (unit tests), 3.4 (Property 1), 3.5 (Property 2)
"""
import json
import sys
import os
from unittest.mock import MagicMock

# ---------------------------------------------------------------------------
# Stub out heavy dependencies so agent.py can be imported without them
# ---------------------------------------------------------------------------
for _mod in ("strands", "strands_tools", "strands.agent", "strands.tools"):
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()

_strands_stub = sys.modules["strands"]
_strands_stub.tool = lambda f: f
_strands_stub.Agent = MagicMock()

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import pytest
from hypothesis import given, settings, assume, strategies as st

from agent import extract_user_identity, AuthError


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def make_event(sub=None, body_user_id=None, email=None):
    """
    Build a minimal API Gateway proxy event.

    - sub: value placed in requestContext.authorizer.claims["sub"]
    - email: value placed in requestContext.authorizer.claims["email"]
    - body_user_id: value placed in the JSON-encoded body as "user_id"
    """
    claims = {}
    if sub is not None:
        claims["sub"] = sub
    if email is not None:
        claims["email"] = email

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
                "claims": claims,
            }
        },
    }


# ---------------------------------------------------------------------------
# Task 3.3 — Unit tests for extract_user_identity
# Requirements: 2.1, 2.4, 2.5
# ---------------------------------------------------------------------------

class TestExtractUserIdentityUnitTests:
    """Example-based unit tests for extract_user_identity."""

    # --- Happy path ---

    def test_valid_claims_returns_sub_email_tuple(self):
        """Valid sub + email → returns (sub, email) tuple. Requirements: 2.1"""
        event = make_event(sub="a1b2c3d4-uuid", email="user@example.com")
        result = extract_user_identity(event)
        assert result == ("a1b2c3d4-uuid", "user@example.com")

    def test_valid_claims_no_email_returns_none_email(self):
        """Valid sub with no email claim → email part is None. Requirements: 2.1"""
        event = make_event(sub="a1b2c3d4-uuid")
        sub, email = extract_user_identity(event)
        assert sub == "a1b2c3d4-uuid"
        assert email is None

    def test_sub_whitespace_is_stripped_from_return_value(self):
        """sub with surrounding spaces is returned stripped. Requirements: 2.1"""
        event = make_event(sub="  trimmed-uuid  ")
        sub, _ = extract_user_identity(event)
        assert sub == "trimmed-uuid"

    # --- Missing requestContext → AuthError(401) ---

    def test_missing_request_context_raises_auth_error_401(self):
        """Missing requestContext key → raises AuthError(401). Requirements: 2.4, 2.5"""
        with pytest.raises(AuthError) as exc:
            extract_user_identity({})
        assert exc.value.status_code == 401

    def test_request_context_is_none_raises_auth_error_401(self):
        """requestContext set to None → raises AuthError(401). Requirements: 2.4"""
        with pytest.raises(AuthError) as exc:
            extract_user_identity({"requestContext": None})
        assert exc.value.status_code == 401

    # --- Missing authorizer key → AuthError(401) ---

    def test_missing_authorizer_key_raises_auth_error_401(self):
        """requestContext exists but no authorizer key → raises AuthError(401). Requirements: 2.4, 2.5"""
        with pytest.raises(AuthError) as exc:
            extract_user_identity({"requestContext": {}})
        assert exc.value.status_code == 401

    # --- Missing claims key → AuthError(401) ---

    def test_missing_claims_key_raises_auth_error_401(self):
        """authorizer exists but no claims key → raises AuthError(401). Requirements: 2.4, 2.5"""
        event = {"requestContext": {"authorizer": {}}}
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401

    # --- Invalid sub values → AuthError(401) ---

    def test_empty_string_sub_raises_auth_error_401(self):
        """sub = "" → raises AuthError(401). Requirements: 2.4, 2.5"""
        event = make_event(sub="")
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401

    def test_whitespace_only_sub_raises_auth_error_401(self):
        """sub is spaces-only → raises AuthError(401). Requirements: 2.4, 2.5"""
        event = make_event(sub="   ")
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401

    def test_tab_newline_sub_raises_auth_error_401(self):
        """sub is tab/newline whitespace → raises AuthError(401). Requirements: 2.4, 2.5"""
        event = make_event(sub="\t\n")
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401

    def test_none_sub_value_raises_auth_error_401(self):
        """claims dict present but sub key maps to None → raises AuthError(401). Requirements: 2.4"""
        event = {
            "requestContext": {
                "authorizer": {
                    "claims": {"sub": None, "email": "user@example.com"},
                }
            }
        }
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401

    def test_missing_sub_key_raises_auth_error_401(self):
        """claims dict has no 'sub' key at all → raises AuthError(401). Requirements: 2.4, 2.5"""
        event = {
            "requestContext": {
                "authorizer": {
                    "claims": {"email": "user@example.com"},
                }
            }
        }
        with pytest.raises(AuthError) as exc:
            extract_user_identity(event)
        assert exc.value.status_code == 401


# ---------------------------------------------------------------------------
# Task 3.4 — Property 1: Identity from sub, not body
# Feature: cognito-api-authentication, Property 1: Identity from sub, not body
# Validates: Requirements 2.1, 2.2, 2.3
# ---------------------------------------------------------------------------

@given(
    body_user_id=st.text(min_size=1).filter(lambda s: s.strip()),
    sub=st.uuids().map(str),
)
@settings(max_examples=100)
def test_identity_always_from_sub(body_user_id, sub):
    """
    **Validates: Requirements 2.1, 2.2, 2.3**

    Property 1: Identity comes exclusively from the sub claim, never from the request body.

    For any combination of an arbitrary user_id value in the request body and a valid sub UUID
    in the authorizer claims, the identity resolved by extract_user_identity must equal the sub
    claim value and must never equal the request-body user_id (when the two differ).
    """
    assume(body_user_id.strip() != sub)
    event = make_event(body_user_id=body_user_id, sub=sub)
    resolved_sub, _ = extract_user_identity(event)
    assert resolved_sub == sub
    assert resolved_sub != body_user_id.strip()


# ---------------------------------------------------------------------------
# Task 3.5 — Property 2: Whitespace sub rejected
# Feature: cognito-api-authentication, Property 2: Whitespace sub rejected
# Validates: Requirements 2.4, 2.5
# ---------------------------------------------------------------------------

@given(sub=st.text(alphabet=" \t\n\r"))
@settings(max_examples=100)
def test_whitespace_sub_rejected(sub):
    """
    **Validates: Requirements 2.4, 2.5**

    Property 2: Whitespace or absent sub claims are always rejected with 401.

    For any string composed entirely of whitespace characters passed as the sub claim,
    extract_user_identity must raise an AuthError with status_code = 401 and must not
    return a user identity.
    """
    event = make_event(sub=sub)
    with pytest.raises(AuthError) as exc:
        extract_user_identity(event)
    assert exc.value.status_code == 401
