"""Uniform error types and response helpers for the Gardening App API."""


class ApiError(Exception):
    """Raised by route handlers and middleware to produce structured HTTP error responses."""

    def __init__(self, status_code: int, error: str, message: str) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.error = error
        self.message = message


def make_error_response(exc: ApiError, request_id: str) -> dict:
    """Build the canonical error response dict for API Gateway proxy integration.

    Returns a dict with statusCode, headers (Content-Type + CORS), and body.
    The body is a JSON-serialisable dict — NOT a pre-serialised string, because
    AWS Lambda Powertools serialises the body automatically.
    """
    return {
        "statusCode": exc.status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": {
            "error": exc.error,
            "message": exc.message,
            "request_id": request_id,
        },
    }
