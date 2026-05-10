-- Creates CI/CD service account users with RSA key-pair authentication.
-- Run as SECURITYADMIN after:
--   1. Running scripts/admin_setup.sql (databases, warehouses, roles)
--   2. Generating key pairs with scripts/generate_keys.sh
--
-- For each RSA_PUBLIC_KEY value: paste the key body from the .pub file,
-- excluding the -----BEGIN PUBLIC KEY----- and -----END PUBLIC KEY----- lines.
-- The value must be a single quoted string with no line breaks.

USE ROLE SECURITYADMIN;

-- Dev service account
CREATE USER IF NOT EXISTS CICD_DEV_SVC
    DEFAULT_ROLE      = CICD_DEV_ROLE
    DEFAULT_WAREHOUSE = DEV_WH
    RSA_PUBLIC_KEY    = '<paste rsa_key_dev.pub body here>'
    COMMENT           = 'CI/CD service account for dev environment';

GRANT ROLE CICD_DEV_ROLE TO USER CICD_DEV_SVC;

-- Test service account
CREATE USER IF NOT EXISTS CICD_TEST_SVC
    DEFAULT_ROLE      = CICD_TEST_ROLE
    DEFAULT_WAREHOUSE = TEST_WH
    RSA_PUBLIC_KEY    = '<paste rsa_key_test.pub body here>'
    COMMENT           = 'CI/CD service account for test environment';

GRANT ROLE CICD_TEST_ROLE TO USER CICD_TEST_SVC;

-- Prod service account
CREATE USER IF NOT EXISTS CICD_PROD_SVC
    DEFAULT_ROLE      = CICD_PROD_ROLE
    DEFAULT_WAREHOUSE = PROD_WH
    RSA_PUBLIC_KEY    = '<paste rsa_key_prod.pub body here>'
    COMMENT           = 'CI/CD service account for prod environment';

GRANT ROLE CICD_PROD_ROLE TO USER CICD_PROD_SVC;

-- ============================================================
-- ADO variable groups required by the pipeline
-- Create these in ADO under Pipelines > Library, one per environment.
-- Mark SNOWFLAKE_PRIVATE_KEY as secret in each group.
-- ============================================================
--
-- Variable group: snowflake-dev
--   SNOWFLAKE_ACCOUNT        <account-identifier>   e.g. xy12345.us-east-1
--   SNOWFLAKE_USER           CICD_DEV_SVC
--   SNOWFLAKE_PRIVATE_KEY    <full content of rsa_key_dev.p8>   (secret)
--   SNOWFLAKE_ROLE           CICD_DEV_ROLE
--   SNOWFLAKE_DATABASE       MYPROJECT_DEV
--   SNOWFLAKE_SCHEMA         PUBLIC   (overridden at runtime to per-dev schema)
--   SNOWFLAKE_WAREHOUSE      DEV_WH
--
-- Variable group: snowflake-test
--   SNOWFLAKE_ACCOUNT        <account-identifier>
--   SNOWFLAKE_USER           CICD_TEST_SVC
--   SNOWFLAKE_PRIVATE_KEY    <full content of rsa_key_test.p8>  (secret)
--   SNOWFLAKE_ROLE           CICD_TEST_ROLE
--   SNOWFLAKE_DATABASE       MYPROJECT_TEST
--   SNOWFLAKE_SCHEMA         PUBLIC
--   SNOWFLAKE_WAREHOUSE      TEST_WH
--
-- Variable group: snowflake-prod
--   SNOWFLAKE_ACCOUNT        <account-identifier>
--   SNOWFLAKE_USER           CICD_PROD_SVC
--   SNOWFLAKE_PRIVATE_KEY    <full content of rsa_key_prod.p8>  (secret)
--   SNOWFLAKE_ROLE           CICD_PROD_ROLE
--   SNOWFLAKE_DATABASE       MYPROJECT_PROD
--   SNOWFLAKE_SCHEMA         PUBLIC
--   SNOWFLAKE_WAREHOUSE      PROD_WH
