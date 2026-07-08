"""Fire-and-forget Lambda self-invocation for async AI tasks."""

import boto3
import json
import logging
import os
from typing import Any

logger = logging.getLogger(__name__)

# Lazily initialised so unit tests can mock before the client is created
_lambda_client = None


def _get_client():
    global _lambda_client
    if _lambda_client is None:
        _lambda_client = boto3.client("lambda")
    return _lambda_client


def trigger_async(payload: dict[str, Any], request_id: str) -> None:
    """Invoke this Lambda function asynchronously with the given payload.

    Uses InvocationType=Event so the call returns immediately without waiting
    for the invoked function to complete. Any exception is swallowed and logged
    so that the calling HTTP handler always returns its response (Req 20.3).

    Args:
        payload: Arbitrary dict that will be wrapped as {"async_task": payload}
                 and passed as the invocation payload.
        request_id: The API Gateway request ID, used for log correlation.
    """
    fn_name = os.environ.get("LAMBDA_FUNCTION_NAME", "")
    if not fn_name:
        logger.error(
            "[request_id=%s] LAMBDA_FUNCTION_NAME env var not set — async trigger skipped.",
            request_id,
        )
        return

    try:
        _get_client().invoke(
            FunctionName=fn_name,
            InvocationType="Event",  # fire-and-forget
            Payload=json.dumps({"async_task": payload}),
        )
        logger.info(
            "[request_id=%s] Async task triggered: action=%s",
            request_id,
            payload.get("action", "unknown"),
        )
    except Exception as exc:  # noqa: BLE001
        # Swallow all exceptions — the HTTP response must never be blocked (Req 20.3)
        logger.error(
            "[request_id=%s] Async trigger failed for action=%s: %s",
            request_id,
            payload.get("action", "unknown"),
            exc,
        )
