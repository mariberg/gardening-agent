"""Upload route handlers for POST /api/v1/uploads/presign to generate S3 pre-signed PUT URLs."""

from aws_lambda_powertools.event_handler import Router

router = Router()
