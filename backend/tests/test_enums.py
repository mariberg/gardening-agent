"""
Tests for src/api/enums.py — five enum classes and validate_enum.

Feature: gardening-app-api-endpoints
Task: 3.1 (unit tests for enums and validate_enum)
"""
import sys
import os
from types import ModuleType
from unittest.mock import MagicMock

# ---------------------------------------------------------------------------
# Stub out src.api.errors so enums.py can be imported before errors.py lands
# ---------------------------------------------------------------------------
errors_stub = ModuleType("src.api.errors")


class _ApiError(Exception):
    """Minimal stub matching the real ApiError(status_code, error, message)."""

    def __init__(self, status_code: int, error: str, message: str):
        self.status_code = status_code
        self.error = error
        self.message = message


errors_stub.ApiError = _ApiError

# Register the stub at every path the import might use
for _name in ("src.api.errors", "api.errors"):
    sys.modules[_name] = errors_stub

# Make sure the src/ package root is on the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import pytest
from hypothesis import given, settings, strategies as st

from api.enums import (
    ActionType,
    Severity,
    LoggedBy,
    SourceType,
    Scope,
    validate_enum,
)


# ===========================================================================
# Enum membership unit tests
# ===========================================================================

class TestActionType:
    def test_all_values_present(self):
        values = {e.value for e in ActionType}
        assert values == {"watered", "pruned", "fertilised", "issue_found", "repotted", "other"}

    def test_is_str_subclass(self):
        assert isinstance(ActionType.watered, str)

    def test_each_member_accessible(self):
        assert ActionType("watered") == ActionType.watered
        assert ActionType("issue_found") == ActionType.issue_found


class TestSeverity:
    def test_all_values_present(self):
        values = {e.value for e in Severity}
        assert values == {"mild", "moderate", "severe"}

    def test_is_str_subclass(self):
        assert isinstance(Severity.mild, str)


class TestLoggedBy:
    def test_all_values_present(self):
        values = {e.value for e in LoggedBy}
        assert values == {"user", "agent"}

    def test_is_str_subclass(self):
        assert isinstance(LoggedBy.user, str)


class TestSourceType:
    def test_all_values_present(self):
        values = {e.value for e in SourceType}
        assert values == {"rhs", "forum", "book", "other"}

    def test_is_str_subclass(self):
        assert isinstance(SourceType.rhs, str)


class TestScope:
    def test_all_values_present(self):
        values = {e.value for e in Scope}
        assert values == {"species", "instance", "garden"}

    def test_is_str_subclass(self):
        assert isinstance(Scope.species, str)


# ===========================================================================
# validate_enum unit tests
# ===========================================================================

class TestValidateEnum:
    # --- ActionType ---
    @pytest.mark.parametrize("v", ["watered", "pruned", "fertilised", "issue_found", "repotted", "other"])
    def test_valid_action_type(self, v):
        assert validate_enum("action_type", v, ActionType) == v

    # --- Severity ---
    @pytest.mark.parametrize("v", ["mild", "moderate", "severe"])
    def test_valid_severity(self, v):
        assert validate_enum("severity", v, Severity) == v

    # --- LoggedBy ---
    @pytest.mark.parametrize("v", ["user", "agent"])
    def test_valid_logged_by(self, v):
        assert validate_enum("logged_by", v, LoggedBy) == v

    # --- SourceType ---
    @pytest.mark.parametrize("v", ["rhs", "forum", "book", "other"])
    def test_valid_source_type(self, v):
        assert validate_enum("source_type", v, SourceType) == v

    # --- Scope ---
    @pytest.mark.parametrize("v", ["species", "instance", "garden"])
    def test_valid_scope(self, v):
        assert validate_enum("scope", v, Scope) == v

    # --- Return type is plain str ---
    def test_returns_plain_string(self):
        result = validate_enum("action_type", "watered", ActionType)
        assert type(result) is str

    # --- Invalid value raises ApiError 400 ---
    def test_invalid_raises_api_error(self):
        with pytest.raises(_ApiError) as exc_info:
            validate_enum("action_type", "WATERED", ActionType)
        err = exc_info.value
        assert err.status_code == 400
        assert err.error == "invalid_enum"

    def test_error_message_contains_field_name(self):
        with pytest.raises(_ApiError) as exc_info:
            validate_enum("severity", "extreme", Severity)
        assert "severity" in exc_info.value.message

    def test_error_message_contains_invalid_value(self):
        with pytest.raises(_ApiError) as exc_info:
            validate_enum("scope", "planet", Scope)
        assert "planet" in exc_info.value.message

    def test_error_message_contains_valid_values(self):
        with pytest.raises(_ApiError) as exc_info:
            validate_enum("logged_by", "bot", LoggedBy)
        msg = exc_info.value.message
        assert "user" in msg
        assert "agent" in msg

    def test_empty_string_invalid(self):
        with pytest.raises(_ApiError):
            validate_enum("action_type", "", ActionType)

    def test_case_sensitive_uppercase_rejected(self):
        with pytest.raises(_ApiError):
            validate_enum("severity", "Mild", Severity)

    def test_case_sensitive_all_caps_rejected(self):
        with pytest.raises(_ApiError):
            validate_enum("scope", "SPECIES", Scope)


# ===========================================================================
# Property-based tests — Property 3: Enum Validation Completeness
# Validates: Requirements 6.1, 6.2, 23.1–23.6
# ===========================================================================

# Strategy: arbitrary text strings
_text = st.text(min_size=0, max_size=40)

# Gather all valid values per enum for use in properties
_VALID = {
    ActionType: frozenset(e.value for e in ActionType),
    Severity: frozenset(e.value for e in Severity),
    LoggedBy: frozenset(e.value for e in LoggedBy),
    SourceType: frozenset(e.value for e in SourceType),
    Scope: frozenset(e.value for e in Scope),
}

_ALL_ENUMS = list(_VALID.keys())


@given(value=_text)
@settings(max_examples=200)
def test_property_valid_value_always_accepted(value):
    """**Validates: Requirements 6.1, 23.1–23.6**

    For every enum class, any string that IS a valid member must be accepted
    (return the same string) and must never raise.
    """
    for enum_class in _ALL_ENUMS:
        if value in _VALID[enum_class]:
            result = validate_enum("field", value, enum_class)
            assert result == value, (
                f"validate_enum rejected valid value {value!r} for {enum_class.__name__}"
            )


@given(value=_text)
@settings(max_examples=200)
def test_property_invalid_value_always_rejected(value):
    """**Validates: Requirements 6.2, 23.1–23.6**

    For every enum class, any string that is NOT a valid member must raise
    ApiError(400, 'invalid_enum', ...) and must never be silently accepted.
    """
    for enum_class in _ALL_ENUMS:
        if value not in _VALID[enum_class]:
            with pytest.raises(_ApiError) as exc_info:
                validate_enum("field", value, enum_class)
            err = exc_info.value
            assert err.status_code == 400, (
                f"Expected status 400, got {err.status_code} for {value!r}"
            )
            assert err.error == "invalid_enum", (
                f"Expected error='invalid_enum', got {err.error!r}"
            )


@given(
    field_name=st.text(min_size=1, max_size=30),
    value=_text,
)
@settings(max_examples=200)
def test_property_field_name_appears_in_error_message(field_name, value):
    """**Validates: Requirements 6.2**

    When validate_enum raises for an invalid value, the error message must
    include the field_name so callers can identify which field was rejected.
    """
    for enum_class in _ALL_ENUMS:
        if value not in _VALID[enum_class]:
            with pytest.raises(_ApiError) as exc_info:
                validate_enum(field_name, value, enum_class)
            assert field_name in exc_info.value.message, (
                f"field_name {field_name!r} not found in message: {exc_info.value.message!r}"
            )
            break  # one enum is enough to check the message contract
