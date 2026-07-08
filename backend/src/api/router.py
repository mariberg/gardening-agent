"""Main API router: registers all /api/v1/* route handlers via AWS Lambda Powertools APIGatewayRestResolver."""

import json
import logging
from typing import Any

from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler import CORSConfig
from aws_lambda_powertools.utilities.typing import LambdaContext

from src.api.errors import ApiError, make_error_response

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Powertools app — CORS config satisfies Req 1.6 / 22.2 globally
# ---------------------------------------------------------------------------
app = APIGatewayRestResolver(
    cors=CORSConfig(allow_origin="*", allow_headers=["Content-Type", "Authorization"])
)

# ---------------------------------------------------------------------------
# Exception handlers
# ---------------------------------------------------------------------------

@app.exception_handler(ApiError)
def handle_api_error(exc: ApiError):
    from aws_lambda_powertools.event_handler.api_gateway import Response
    request_id = _get_request_id()
    logger.warning("[request_id=%s] ApiError %s: %s", request_id, exc.error, exc.message)
    return Response(
        status_code=exc.status_code,
        content_type="application/json",
        headers={"Access-Control-Allow-Origin": "*"},
        body=json.dumps({
            "error": exc.error,
            "message": exc.message,
            "request_id": request_id,
        }),
    )


@app.exception_handler(Exception)
def handle_unhandled(exc: Exception):
    from aws_lambda_powertools.event_handler.api_gateway import Response
    request_id = _get_request_id()
    logger.exception("[request_id=%s] Unhandled exception", request_id)
    return Response(
        status_code=500,
        content_type="application/json",
        headers={"Access-Control-Allow-Origin": "*"},
        body=json.dumps({
            "error": "internal_error",
            "message": "An unexpected error occurred.",
            "request_id": request_id,
        }),
    )


def _get_request_id() -> str:
    """Safely extract the API Gateway request ID from the current event context."""
    try:
        return app.current_event.request_context.request_id or "unknown"
    except AttributeError:
        return "unknown"


# ---------------------------------------------------------------------------
# Route registration — import each route module and include its router
# ---------------------------------------------------------------------------
# Imports are deferred to avoid circular imports with middleware.py which
# itself imports `app` from this module.

def _register_routes():
    from src.api.routes import (  # noqa: PLC0415
        plants,
        action_logs,
        watering,
        dashboard,
        users,
        uploads,
        photos,
        care_instructions,
        agent,
    )
    prefix = "/api/v1"
    app.include_router(plants.router, prefix=prefix)
    app.include_router(action_logs.router, prefix=prefix)
    app.include_router(watering.router, prefix=prefix)
    app.include_router(dashboard.router, prefix=prefix)
    app.include_router(users.router, prefix=prefix)
    app.include_router(uploads.router, prefix=prefix)
    app.include_router(photos.router, prefix=prefix)
    app.include_router(care_instructions.router, prefix=prefix)
    app.include_router(agent.router, prefix=prefix)


_register_routes()


# ---------------------------------------------------------------------------
# Async task dispatcher — called when event contains "async_task" key
# ---------------------------------------------------------------------------

def handle_async_task(payload: dict[str, Any]) -> dict:
    """Route an async task payload to the appropriate AI agent logic.

    This is the entry point for fire-and-forget Lambda self-invocations
    triggered by trigger_async().
    """
    action = payload.get("action", "")
    logger.info("Handling async task: action=%s", action)

    # Stub dispatcher — individual actions will be implemented in wave 4+
    if action == "session_open":
        _handle_session_open(payload)
    elif action == "analyse_photo":
        _handle_analyse_photo(payload)
    elif action == "recalculate_watering":
        _handle_recalculate_watering(payload)
    elif action == "review_care_instruction":
        _handle_review_care_instruction(payload)
    else:
        logger.warning("Unknown async task action: %s", action)

    return {"status": "ok"}


def _handle_session_open(payload: dict) -> None:
    """Stub: refresh dashboard summary and recalculate watering schedules."""
    logger.info("session_open stub: garden_id=%s", payload.get("garden_id"))


def _handle_analyse_photo(payload: dict) -> None:
    """Stub: run AI photo analysis and store result in GardenData."""
    logger.info("analyse_photo stub: photo_id=%s", payload.get("photo_id"))


def _handle_recalculate_watering(payload: dict) -> None:
    """Stub: recalculate next_watering_date for affected plant instances."""
    logger.info("recalculate_watering stub: instance_ids=%s", payload.get("instance_ids"))


def _handle_review_care_instruction(payload: dict) -> None:
    """Stub: AI review of a newly submitted care instruction."""
    logger.info("review_care_instruction stub: instruction_id=%s", payload.get("instruction_id"))


# ---------------------------------------------------------------------------
# Lambda entry point
# ---------------------------------------------------------------------------

def lambda_handler(event: dict, context: LambdaContext) -> dict:
    """AWS Lambda entry point for the Gardening API Handler function.

    Handles two event types:
    - API Gateway proxy events (routed to Powertools APIGatewayRestResolver)
    - Async task events (containing "async_task" key, fire-and-forget from trigger_async)
    """
    if "async_task" in event:
        return handle_async_task(event["async_task"])
    return app.resolve(event, context)
