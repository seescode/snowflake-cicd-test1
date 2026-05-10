#!/usr/bin/env bash
set -euo pipefail

# Deploy Snowflake objects in dependency order: tables -> views -> stored_procedures.
# Connection is configured via environment variables picked up automatically by
# the Snowflake CLI. For local development use ~/.snowflake/config.toml instead.

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

# Create the target schema if it doesn't exist (required for per-developer
# dev schemas, which are not pre-created by admin_setup.sql).
snow sql -q "CREATE SCHEMA IF NOT EXISTS ${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA};"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNOWFLAKE_DIR="$SCRIPT_DIR/../snowflake"

deploy_dir() {
  local dir="$1"
  local count=0
  echo "--- $dir ---"
  for sql_file in "$SNOWFLAKE_DIR/$dir"/*.sql; do
    [[ -f "$sql_file" ]] || continue
    echo "  deploying $(basename "$sql_file")"
    snow sql -f "$sql_file"
    (( count++ ))
  done
  echo "  $count file(s) deployed"
}

deploy_dir tables
deploy_dir views
deploy_dir stored_procedures

echo "Deploy complete."
