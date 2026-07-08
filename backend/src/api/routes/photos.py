"""Photo route handlers for GET /api/v1/photos/{photo_id} and GET /api/v1/plants/{instance_id}/photos."""

from aws_lambda_powertools.event_handler import Router

router = Router()
