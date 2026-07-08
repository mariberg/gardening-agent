"""Garden resolution middleware: resolves Cognito sub to garden_id and injects it into handler context."""

import functools
import logging
from typing import Callable

from src.api.errors import ApiError

logger = logging.getLogger(__name__)


def require_garden(fn: Callable) -> Callable:
    """Decorator that resolves the caller's garden_id from their Cognito sub claim.

    Extracts the ``sub`` JWT claim injected by API Gateway, looks up the
    corresponding UserProfiles record, and injects ``garden_id`` and
    ``user_id`` as keyword arguments into the decorated handler.

    Raises:
        ApiError(401, "invalid_sub"): when the sub claim is absent or whitespace.
        ApiError(401, "no_profile"): when no UserProfiles record exists for the sub.

    Requirements: 1.3, 1.4
    """

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        # Lazy import to avoid circular dependency with router.py
        from src.api.router import app  # noqa: PLC0415

        from src.api.dal.user_profiles import get_profile_by_sub  # noqa: PLC0415

        # Extract sub claim from API Gateway authorizer context
        try:
            claims = app.current_event.request_context.authorizer.claims or {}
        except AttributeError:
            claims = {}

        sub = (claims.get("sub") or "").strip()
        if not sub:
            raise ApiError(401, "invalid_sub", "Token sub claim is missing.")

        profile = get_profile_by_sub(sub)
        if not profile:
            raise ApiError(
                401,
                "no_profile",
                "No user profile associated with this token.",
            )

        kwargs["garden_id"] = profile["garden_id"]
        kwargs["user_id"] = profile["user_id"]
        return fn(*args, **kwargs)

    return wrapper
