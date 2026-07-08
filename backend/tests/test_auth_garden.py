"""
Tests for resolve_garden_id in agent.py.

Feature: cognito-api-authentication
Tasks: 4.3 (unit tests), 4.4 (Property 4), 4.5 (Property 5), 4.6 (Property 6)
"""
import sys
import os
import pytest
from unittest.mock import MagicMock

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

from hypothesis import given, settings, strategies as st

from agent import resolve_garden_id, AuthError


# ---------------------------------------------------------------------------
# MockUserProfilesTable — returns its items list from .scan(), ignoring
# filter expressions (the filter is applied server-side in production).
# ---------------------------------------------------------------------------

class MockUserProfilesTable:
    """Minimal DynamoDB Table mock for resolve_garden_id tests."""

    def __init__(self, items):
        self._items = list(items)

    def scan(self, **kwargs):
        return {"Items": self._items}


# ===========================================================================
# Task 4.3 — Unit tests for resolve_garden_id
# Requirements: 3.1, 3.4, 3.8
# ===========================================================================

class TestResolveGardenIdUnit:
    """Example-based unit tests for resolve_garden_id."""

    def test_found_mapping_returns_user_id_and_garden_id(self):
        """Found mapping → returns (user_id, garden_id). Requirements: 3.1"""
        table = MockUserProfilesTable([
            {"user_id": "alice", "cognito_sub": "sub-uuid-001", "garden_id": "garden_001"}
        ])
        user_id, garden_id = resolve_garden_id("sub-uuid-001", table)
        assert user_id == "alice"
        assert garden_id == "garden_001"

    def test_empty_items_raises_403_no_garden_association(self):
        """No record (empty Items) → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
        table = MockUserProfilesTable([])
        with pytest.raises(AuthError) as exc_info:
            resolve_garden_id("sub-uuid-missing", table)
        assert exc_info.value.status_code == 403
        assert exc_info.value.error_code == "no_garden_association"

    def test_record_without_garden_id_raises_403(self):
        """Record with no garden_id field → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
        table = MockUserProfilesTable([
            {"user_id": "alice", "cognito_sub": "sub-uuid-001"}
            # garden_id key absent
        ])
        with pytest.raises(AuthError) as exc_info:
            resolve_garden_id("sub-uuid-001", table)
        assert exc_info.value.status_code == 403
        assert exc_info.value.error_code == "no_garden_association"

    def test_record_with_empty_garden_id_raises_403(self):
        """Record with garden_id='' (falsy) → raises AuthError(403, 'no_garden_association'). Requirements: 3.4"""
        table = MockUserProfilesTable([
            {"user_id": "alice", "cognito_sub": "sub-uuid-001", "garden_id": ""}
        ])
        with pytest.raises(AuthError) as exc_info:
            resolve_garden_id("sub-uuid-001", table)
        assert exc_info.value.status_code == 403
        assert exc_info.value.error_code == "no_garden_association"

    def test_dynamodb_exception_raises_500_membership_lookup_failed(self):
        """DynamoDB throws exception → raises AuthError(500, 'membership_lookup_failed'). Requirements: 3.8"""
        class BrokenTable:
            def scan(self, **kwargs):
                raise RuntimeError("DynamoDB connection refused")

        with pytest.raises(AuthError) as exc_info:
            resolve_garden_id("sub-uuid-001", BrokenTable())
        assert exc_info.value.status_code == 500
        assert exc_info.value.error_code == "membership_lookup_failed"


# ===========================================================================
# Task 4.4 — Property 4: Correct garden resolution from UserProfiles
# Validates: Requirements 3.1, 3.2, 9.2, 9.3
# ===========================================================================

# Feature: cognito-api-authentication, Property 4: Correct garden resolution
@given(
    sub=st.uuids().map(str),
    user_id=st.text(
        min_size=1,
        max_size=50,
        alphabet=st.characters(
            whitelist_categories=("Lu", "Ll", "Nd"),
            whitelist_characters="_-",
        ),
    ),
    garden_id=st.text(min_size=1, max_size=50),
)
@settings(max_examples=100)
def test_resolve_garden_id_correctness(sub, user_id, garden_id):
    """
    **Validates: Requirements 3.1, 3.2, 9.2, 9.3**

    Property 4: Correct garden resolution from UserProfiles.

    For any (sub, legacy_user_id, garden_id) triple where a UserProfiles record exists
    with cognito_sub=sub, user_id=legacy_user_id, and garden_id=garden_id,
    calling resolve_garden_id(sub, table) must return (legacy_user_id, garden_id) exactly.
    """
    mock_table = MockUserProfilesTable([
        {"user_id": user_id, "cognito_sub": sub, "garden_id": garden_id}
    ])
    resolved_user_id, resolved_garden_id = resolve_garden_id(sub, mock_table)
    assert resolved_user_id == user_id
    assert resolved_garden_id == garden_id


# ===========================================================================
# Task 4.5 — Property 5: Missing UserProfiles record yields 403, never garden data
# Validates: Requirements 3.4, 7.5, 9.4, 9.5
# ===========================================================================

# Feature: cognito-api-authentication, Property 5: Missing record yields 403
@given(sub=st.uuids().map(str))
@settings(max_examples=100)
def test_missing_record_yields_403(sub):
    """
    **Validates: Requirements 3.4, 7.5, 9.4, 9.5**

    Property 5: Missing UserProfiles record yields 403, never garden data.

    For any sub UUID for which no UserProfiles record with a matching cognito_sub exists,
    resolve_garden_id must raise an AuthError with status_code=403 and must not return
    any garden data.
    """
    mock_table = MockUserProfilesTable([])  # empty table
    with pytest.raises(AuthError) as exc:
        resolve_garden_id(sub, mock_table)
    assert exc.value.status_code == 403
    assert exc.value.error_code == "no_garden_association"


# ===========================================================================
# Task 4.6 — Property 6: Mapping lookup before garden membership
# Validates: Requirements 9.2, 9.3, 9.4
# ===========================================================================

# Feature: cognito-api-authentication, Property 6: Mapping lookup before garden membership
@given(
    sub=st.uuids().map(str),
    user_id=st.text(min_size=1, max_size=20),
    garden_id=st.text(min_size=1, max_size=20),
)
@settings(max_examples=100)
def test_scan_called_before_garden_id_returned(sub, user_id, garden_id):
    """
    **Validates: Requirements 9.2, 9.3, 9.4**

    Property 6: Identity resolution cascade — mapping lookup (scan for cognito_sub)
    is always called before any data is returned.

    Verify via mock instrumentation that user_profiles_table.scan is always called
    before returning a garden_id. There must be no path through the function that
    skips the mapping lookup.
    """
    scan_calls = []

    class InstrumentedTable:
        def scan(self, **kwargs):
            scan_calls.append(kwargs)
            return {"Items": [{"user_id": user_id, "cognito_sub": sub, "garden_id": garden_id}]}

    result = resolve_garden_id(sub, InstrumentedTable())
    assert len(scan_calls) >= 1, "scan must be called before returning garden data"
    assert result == (user_id, garden_id)
