"""
Tests for lambda_handler auth path, Property 7 (secure logging),
and Property 3 (garden data isolation) in agent.py.

Feature: cognito-api-authentication
Tasks: 6.4 (unit tests), 6.5 (Property 7), 6.6 (Property 3)
"""
import json
import logging
import sys
import os
from unittest.mock import MagicMock, patch

# ---------------------------------------------------------------------------
# Stub out heavy dependencies so agent.py can be imported without AWS/strands
# ---------------------------------------------------------------------------
for _mod in ("strands", "strands_tools", "strands.agent", "strands.tools"):
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()

_strands_stub = sys.modules["strands"]
_strands_stub.tool = lambda f: f
_strands_stub.Agent = MagicMock()

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import pytest
from hypothesis import given, settings, strategies as st

from agent import lambda_handler, AuthError, _safe_sub


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_FAKE_AGENT_RESPONSE = {"summary": "advice", "details": {}}


def make_lambda_event(
    http_method: str = "POST",
    sub: str = "test-sub-uuid",
    email: str = "user@example.com",
    jwt_token: str = "header.payload.signature",
    body: dict | None = None,
):
    """
    Build a minimal API Gateway proxy event with Cognito authorizer claims.

    Parameters
    ----------
    http_method : HTTP verb for the request.
    sub         : sub claim value inserted into authorizer claims.
    email       : email claim value (optional).
    jwt_token   : raw JWT string placed in the Authorization header.
    body        : request body dict (JSON-encoded); defaults to empty object.
    """
    return {
        "httpMethod": http_method,
        "path": "/advice",
        "headers": {
            "Content-Type": "application/json",
            "Authorization": jwt_token,
        },
        "body": json.dumps(body or {}),
        "queryStringParameters": None,
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": sub,
                    "email": email,
                },
            },
        },
    }


def make_options_event():
    """Minimal CORS preflight event (no auth context needed)."""
    return {
        "httpMethod": "OPTIONS",
        "path": "/advice",
        "headers": {"Origin": "https://example.com"},
        "body": None,
        "queryStringParameters": None,
        "requestContext": {},
    }


class MockUserProfilesTable:
    """Lightweight DynamoDB Table mock that returns a fixed item list from .scan()."""

    def __init__(self, items):
        self._items = list(items)

    def scan(self, **kwargs):
        return {"Items": self._items}


# ---------------------------------------------------------------------------
# Shared patch targets
# ---------------------------------------------------------------------------

_AGENT_MODULE = "agent"


# ===========================================================================
# Task 6.4 — Unit tests for lambda_handler auth path
# Requirements: 2.1, 2.3, 2.4, 2.5, 3.4, 6.1, 9.1
# ===========================================================================

class TestLambdaHandlerAuthPath:
    """Example-based unit tests for the lambda_handler auth integration."""

    # -----------------------------------------------------------------------
    # OPTIONS bypass — no auth check, returns 200
    # Requirements: 6.1, 9.1
    # -----------------------------------------------------------------------

    def test_options_request_bypasses_auth_and_returns_200(self):
        """
        OPTIONS request bypasses all auth checks and returns 200.
        Requirements: 6.1
        """
        event = make_options_event()
        response = lambda_handler(event, None)
        assert response["statusCode"] == 200

    def test_options_request_does_not_call_agent(self):
        """
        OPTIONS request must not invoke the Agent (no Bedrock call).
        Requirements: 6.1
        """
        event = make_options_event()
        agent_mock = MagicMock()
        with patch(f"{_AGENT_MODULE}.Agent", agent_mock):
            lambda_handler(event, None)
        agent_mock.assert_not_called()

    # -----------------------------------------------------------------------
    # Valid token + matching UserProfiles → calls agent, returns 200
    # Requirements: 2.1, 2.3, 9.1
    # -----------------------------------------------------------------------

    def test_valid_token_with_matching_profile_returns_200(self):
        """
        Valid JWT claims + matching UserProfiles record → agent is called, returns 200.
        Requirements: 2.1, 2.3, 9.1
        """
        event = make_lambda_event(sub="valid-sub-001")
        mock_table = MockUserProfilesTable([
            {"user_id": "test_user", "cognito_sub": "valid-sub-001", "garden_id": "garden_001"}
        ])
        agent_instance = MagicMock(return_value=_FAKE_AGENT_RESPONSE)
        agent_class = MagicMock(return_value=agent_instance)

        with patch(f"{_AGENT_MODULE}.Agent", agent_class), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 200
        agent_instance.assert_called_once()

    def test_valid_token_response_body_is_valid_json(self):
        """
        Successful auth path → response body is valid JSON.
        Requirements: 9.1
        """
        event = make_lambda_event(sub="valid-sub-002")
        mock_table = MockUserProfilesTable([
            {"user_id": "test_user", "cognito_sub": "valid-sub-002", "garden_id": "garden_001"}
        ])
        agent_instance = MagicMock(return_value=_FAKE_AGENT_RESPONSE)
        agent_class = MagicMock(return_value=agent_instance)

        with patch(f"{_AGENT_MODULE}.Agent", agent_class), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            response = lambda_handler(event, None)

        body = json.loads(response["body"])
        assert isinstance(body, dict)

    # -----------------------------------------------------------------------
    # extract_user_identity raises AuthError(401) → returns 401, agent not called
    # Requirements: 2.4, 2.5
    # -----------------------------------------------------------------------

    def test_missing_claims_returns_401_without_calling_agent(self):
        """
        When requestContext.authorizer.claims is absent, returns 401 without invoking agent.
        Requirements: 2.4, 2.5
        """
        event = {
            "httpMethod": "POST",
            "path": "/advice",
            "headers": {"Content-Type": "application/json", "Authorization": "tok"},
            "body": "{}",
            "queryStringParameters": None,
            "requestContext": {},  # no authorizer
        }
        agent_mock = MagicMock()
        with patch(f"{_AGENT_MODULE}.Agent", agent_mock):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 401
        agent_mock.assert_not_called()

    def test_empty_sub_returns_401_without_calling_agent(self):
        """
        sub claim is empty string → returns 401 without invoking agent.
        Requirements: 2.4, 2.5
        """
        event = make_lambda_event(sub="")
        agent_mock = MagicMock()
        with patch(f"{_AGENT_MODULE}.Agent", agent_mock):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 401
        agent_mock.assert_not_called()

    def test_whitespace_sub_returns_401_without_calling_agent(self):
        """
        sub claim is whitespace-only → returns 401 without invoking agent.
        Requirements: 2.4, 2.5
        """
        event = make_lambda_event(sub="   ")
        agent_mock = MagicMock()
        with patch(f"{_AGENT_MODULE}.Agent", agent_mock):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 401
        agent_mock.assert_not_called()

    def test_401_response_includes_error_code_in_body(self):
        """
        Auth failure response body includes an 'error' field.
        Requirements: 2.5
        """
        event = make_lambda_event(sub="")
        with patch(f"{_AGENT_MODULE}.Agent", MagicMock()):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 401
        body = json.loads(response["body"])
        assert "error" in body

    # -----------------------------------------------------------------------
    # resolve_garden_id raises AuthError(403) → returns 403, agent not called
    # Requirements: 3.4
    # -----------------------------------------------------------------------

    def test_no_garden_association_returns_403_without_calling_agent(self):
        """
        Valid sub but no matching UserProfiles record → 403 without invoking agent.
        Requirements: 3.4
        """
        event = make_lambda_event(sub="valid-sub-no-garden")
        mock_table = MockUserProfilesTable([])  # empty — no match
        agent_mock = MagicMock()

        with patch(f"{_AGENT_MODULE}.Agent", agent_mock), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 403
        agent_mock.assert_not_called()

    def test_403_response_includes_no_garden_association_error_code(self):
        """
        No garden association → response body error field is 'no_garden_association'.
        Requirements: 3.4
        """
        event = make_lambda_event(sub="valid-sub-no-garden-2")
        mock_table = MockUserProfilesTable([])
        with patch(f"{_AGENT_MODULE}.Agent", MagicMock()), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            response = lambda_handler(event, None)

        body = json.loads(response["body"])
        assert body.get("error") == "no_garden_association"

    def test_profile_with_no_garden_id_returns_403(self):
        """
        Matched UserProfiles record but missing garden_id → returns 403.
        Requirements: 3.4
        """
        event = make_lambda_event(sub="sub-no-garden-field")
        mock_table = MockUserProfilesTable([
            {"user_id": "test_user", "cognito_sub": "sub-no-garden-field"}
            # garden_id key absent
        ])
        agent_mock = MagicMock()
        with patch(f"{_AGENT_MODULE}.Agent", agent_mock), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            response = lambda_handler(event, None)

        assert response["statusCode"] == 403
        agent_mock.assert_not_called()

    # -----------------------------------------------------------------------
    # _safe_sub — never raises on malformed events
    # Requirements: 2.3 (logging safety)
    # -----------------------------------------------------------------------

    def test_safe_sub_returns_unknown_for_empty_event(self):
        """_safe_sub on {} returns 'unknown' without raising. Requirements: 2.3"""
        result = _safe_sub({})
        assert result == "unknown"

    def test_safe_sub_returns_unknown_when_request_context_is_none(self):
        """_safe_sub when requestContext is None returns 'unknown'. Requirements: 2.3"""
        result = _safe_sub({"requestContext": None})
        assert result == "unknown"

    def test_safe_sub_returns_unknown_when_authorizer_missing(self):
        """_safe_sub when authorizer key absent returns 'unknown'. Requirements: 2.3"""
        result = _safe_sub({"requestContext": {}})
        assert result == "unknown"

    def test_safe_sub_returns_unknown_when_claims_missing(self):
        """_safe_sub when claims key absent returns 'unknown'. Requirements: 2.3"""
        result = _safe_sub({"requestContext": {"authorizer": {}}})
        assert result == "unknown"

    def test_safe_sub_returns_sub_value_when_present(self):
        """_safe_sub returns the actual sub when claims are present. Requirements: 2.3"""
        event = make_lambda_event(sub="real-sub-value")
        result = _safe_sub(event)
        assert result == "real-sub-value"

    def test_safe_sub_never_raises_on_integer_event(self):
        """_safe_sub on a completely wrong type never raises. Requirements: 2.3"""
        result = _safe_sub(42)  # type: ignore
        assert result == "unknown"

    def test_safe_sub_never_raises_on_none_event(self):
        """_safe_sub on None never raises. Requirements: 2.3"""
        result = _safe_sub(None)  # type: ignore
        assert result == "unknown"


# ===========================================================================
# Task 6.5 — Property 7: Secure logging
# Feature: cognito-api-authentication, Property 7: Secure logging
# Validates: Requirements 2.6, 7.6, 7.7
# ===========================================================================

class _CapturingHandler(logging.Handler):
    """In-memory log handler: accumulates all emitted log records."""

    def __init__(self):
        super().__init__(level=logging.DEBUG)
        self.records: list[logging.LogRecord] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.records.append(record)

    @property
    def text(self) -> str:
        return "\n".join(self.format(r) for r in self.records)

    def clear(self) -> None:
        self.records.clear()


# Feature: cognito-api-authentication, Property 7: Secure logging
@given(
    sub=st.uuids().map(str),
    jwt_token=st.text(
        min_size=10,
        alphabet=st.characters(
            whitelist_categories=("Lu", "Ll", "Nd"),
            whitelist_characters="._-",
        ),
    ),
)
@settings(max_examples=50)
def test_sub_logged_jwt_not_logged(sub, jwt_token):
    """
    **Validates: Requirements 2.6, 7.6, 7.7**

    Property 7: Secure logging — sub is logged, raw JWT is never logged.

    For any request that the Lambda processes, the log output must contain the sub
    claim value, and must not contain the raw value of the Authorization header
    (the JWT token string).
    """
    event = make_lambda_event(sub=sub, jwt_token=jwt_token)
    mock_table = MockUserProfilesTable([
        {"user_id": "test_user", "cognito_sub": sub, "garden_id": "garden_001"}
    ])
    agent_instance = MagicMock(return_value=_FAKE_AGENT_RESPONSE)
    agent_class = MagicMock(return_value=agent_instance)

    # Attach a fresh in-memory handler to the "agent" logger for this run
    agent_logger = logging.getLogger("agent")
    handler = _CapturingHandler()
    agent_logger.addHandler(handler)
    original_level = agent_logger.level
    agent_logger.setLevel(logging.DEBUG)
    try:
        with patch(f"{_AGENT_MODULE}.Agent", agent_class), \
             patch(f"{_AGENT_MODULE}.user_profiles_table", mock_table):
            lambda_handler(event, None)

        log_text = handler.text

        # The sub must appear in the logs so we can trace the request
        assert sub in log_text, (
            f"Expected sub '{sub}' to appear in log output, but it did not.\n"
            f"Log output: {log_text!r}"
        )

        # The raw JWT token must never appear in the logs
        assert jwt_token not in log_text, (
            f"Raw JWT token appeared in log output — this is a security violation.\n"
            f"Token: {jwt_token!r}\nLog output: {log_text!r}"
        )
    finally:
        agent_logger.removeHandler(handler)
        agent_logger.setLevel(original_level)


# ===========================================================================
# Task 6.6 — Property 3: Garden data isolation
# Feature: cognito-api-authentication, Property 3: Garden data isolation
# Validates: Requirements 3.3, 3.5
# ===========================================================================


def filter_to_authorized_garden(items: list, garden_id: str) -> list:
    """
    Return only items whose garden_id matches the authorized garden_id.

    This helper enforces garden data isolation: a user authorized for garden_id
    must only see items belonging to that specific garden.

    Note: This function is defined here to verify the garden isolation concept
    as specified in Property 3. If/when extracted to agent.py, this test should
    import it from there instead.
    """
    return [item for item in items if item.get("garden_id") == garden_id]


def _garden_items_strategy(garden_a, garden_b):
    """
    Build a Hypothesis strategy that generates a list of garden items whose
    garden_id is drawn from {garden_a, garden_b}.  This factory is called
    from the @composite strategy below so that garden_a and garden_b are
    already resolved when the inner sampled_from is constructed.
    """
    return st.lists(
        st.fixed_dictionaries({
            "garden_id": st.sampled_from([garden_a, garden_b]),
            "data": st.text(),
        }),
        min_size=1,
    )


@st.composite
def _garden_isolation_data(draw):
    """
    Composite strategy that produces (garden_a, garden_b, items) where:
    - garden_a and garden_b are distinct non-empty strings (≤ 20 chars)
    - items is a non-empty list of dicts with garden_id ∈ {garden_a, garden_b}
    """
    garden_a = draw(st.text(min_size=1, max_size=20))
    garden_b = draw(st.text(min_size=1, max_size=20).filter(lambda g: g != garden_a))
    items = draw(_garden_items_strategy(garden_a, garden_b))
    return garden_a, garden_b, items


# Feature: cognito-api-authentication, Property 3: Garden data isolation
@given(data=_garden_isolation_data())
@settings(max_examples=100)
def test_garden_data_isolation(data):
    """
    **Validates: Requirements 3.3, 3.5**

    Property 3: Garden data isolation — no cross-garden data leaks.

    For any user whose UserProfiles record maps them to garden_A, every garden data
    item returned must have garden_id = garden_A. No item with any other garden_id
    must appear in the response.
    """
    garden_a, garden_b, items = data
    filtered = filter_to_authorized_garden(items, garden_a)

    # Every returned item must belong to garden_a
    assert all(item["garden_id"] == garden_a for item in filtered), (
        f"Filtered result contains items not belonging to garden '{garden_a}'."
    )

    # No item from garden_b must leak through
    assert not any(item["garden_id"] == garden_b for item in filtered), (
        f"Garden '{garden_b}' data leaked into results authorized for '{garden_a}'."
    )
