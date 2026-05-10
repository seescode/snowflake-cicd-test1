-- Smoke tests for Snowflake native objects.
-- Run via: snow sql -f scripts/smoke_test.sql
-- Any failing statement causes a non-zero exit code and fails the CI step.

-- Verify tables are deployed and columns are accessible
DESCRIBE TABLE members;
DESCRIBE TABLE providers;
DESCRIBE TABLE claims;

-- Verify view resolves (JOIN logic is valid against deployed tables)
DESCRIBE VIEW vw_claims_summary;
SELECT * FROM vw_claims_summary LIMIT 0;

-- Verify stored procedure is deployed and callable.
-- A non-existent claim_id returns an error string — it does not raise an exception.
CALL process_claim('00000000-0000-0000-0000-000000000000');
