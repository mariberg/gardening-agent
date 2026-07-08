"""Enumerated field definitions and validate_enum helper for request boundary validation."""

from enum import Enum

# NOTE: ApiError is imported from src.api.errors.
# errors.py must be present and implement ApiError(status_code, error, message).
from src.api.errors import ApiError


class ActionType(str, Enum):
    watered = "watered"
    pruned = "pruned"
    fertilised = "fertilised"
    issue_found = "issue_found"
    repotted = "repotted"
    other = "other"


class Severity(str, Enum):
    mild = "mild"
    moderate = "moderate"
    severe = "severe"


class LoggedBy(str, Enum):
    user = "user"
    agent = "agent"


class SourceType(str, Enum):
    rhs = "rhs"
    forum = "forum"
    book = "book"
    other = "other"


class Scope(str, Enum):
    species = "species"
    instance = "instance"
    garden = "garden"


def validate_enum(field_name: str, value: str, enum_class) -> str:
    """Validate *value* against *enum_class* at the request boundary.

    Returns the canonical string value (i.e. ``enum_class(value).value``) when
    *value* is a valid member of the enum.

    Raises:
        ApiError(400, "invalid_enum", ...): when *value* is not a member of
            *enum_class*, including the field name and the list of valid values
            in the error message.
    """
    try:
        return enum_class(value).value
    except ValueError:
        valid_values = [e.value for e in enum_class]
        raise ApiError(
            400,
            "invalid_enum",
            f"'{field_name}' must be one of {valid_values}, got '{value}'",
        )
