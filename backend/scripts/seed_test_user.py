#!/usr/bin/env python3
"""
Seed script: creates (or updates) the test_user record in the UserProfiles DynamoDB table.

Usage:
    python scripts/seed_test_user.py [--table-name UserProfiles-dev] [--region eu-west-1]

Requirements: 9.2, 9.3

Test JWT claims
---------------
When writing integration tests or making manual API calls, use this sub in the
Authorization token's claims:

    cognito_sub: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

Example Cognito JWT payload (decoded):
    {
      "sub":   "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "email": "test@example.com",
      ...
    }
"""

import argparse
import boto3
import json
import sys

# ---------------------------------------------------------------------------
# Test user record
# The cognito_sub value below is the canonical sub for the test_user record.
# Use this UUID when minting test JWT claims or seeding other test systems.
# ---------------------------------------------------------------------------
TEST_USER_RECORD = {
    "user_id": "test_user",
    "cognito_sub": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",  # use in test JWT claims
    "garden_id": "garden_001",
    "display_name": "Test User",
    "email": "test@example.com",
    "latitude": "51.5074",
    "longitude": "-0.1278",
    "created_at": "2026-01-15T10:00:00Z",
}


def seed_test_user(table_name: str, region: str, dry_run: bool = False) -> None:
    """Insert (or overwrite) the test_user record in the given UserProfiles table."""
    print(f"Target table : {table_name}")
    print(f"Region       : {region}")
    print(f"Record       : {json.dumps(TEST_USER_RECORD, indent=2)}")

    if dry_run:
        print("\n[dry-run] No changes written.")
        return

    dynamodb = boto3.resource("dynamodb", region_name=region)
    table = dynamodb.Table(table_name)

    table.put_item(Item=TEST_USER_RECORD)
    print(f"\n✓ Seeded test_user record into {table_name}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Seed the test_user UserProfiles record for local/dev testing."
    )
    parser.add_argument(
        "--table-name",
        default="UserProfiles",
        help="DynamoDB table name (default: UserProfiles)",
    )
    parser.add_argument(
        "--region",
        default="eu-west-1",
        help="AWS region (default: eu-west-1)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the record without writing to DynamoDB",
    )
    args = parser.parse_args()

    try:
        seed_test_user(
            table_name=args.table_name,
            region=args.region,
            dry_run=args.dry_run,
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
