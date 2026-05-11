#!/usr/bin/env bash
set -euo pipefail

REQUIRED_VARS=(
  SNOWFLAKE_ACCOUNT
  SNOWFLAKE_USER
  SNOWFLAKE_PRIVATE_KEY_PATH
  SNOWFLAKE_ROLE
  SNOWFLAKE_DATABASE
  SNOWFLAKE_SCHEMA
  SNOWFLAKE_WAREHOUSE
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: required environment variable $var is not set" >&2
    exit 1
  fi
done

echo "Deploying to: $SNOWFLAKE_DATABASE.$SNOWFLAKE_SCHEMA (role=$SNOWFLAKE_ROLE, warehouse=$SNOWFLAKE_WAREHOUSE)"


# Resolve paths relative to this script so it works from any working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run from the snowflake/ directory so !source paths in deploy.sql resolve correctly
cd "$SCRIPT_DIR/../snowflake"
snow sql -f deploy.sql -D db="$SNOWFLAKE_DATABASE" -D schema="$SNOWFLAKE_SCHEMA" -D wh="$SNOWFLAKE_WAREHOUSE"