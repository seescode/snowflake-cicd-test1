-- One-time admin setup script. Run as SYSADMIN / SECURITYADMIN.
-- Replace MYPROJECT with your actual project name before running.
-- Run this script once when onboarding a new project. The CI/CD pipeline
-- does not run this script; it is executed manually by a Snowflake admin.

-- ============================================================
-- Databases (one per environment)
-- ============================================================
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS MYPROJECT_DEV;
CREATE DATABASE IF NOT EXISTS MYPROJECT_TEST;
CREATE DATABASE IF NOT EXISTS MYPROJECT_PROD;

-- ============================================================
-- Virtual warehouses (one per environment, right-sized)
-- ============================================================
CREATE WAREHOUSE IF NOT EXISTS DEV_WH
    WAREHOUSE_SIZE   = XSMALL
    AUTO_SUSPEND     = 60
    AUTO_RESUME      = TRUE
    COMMENT          = 'CI/CD and developer workloads for dev environment';

CREATE WAREHOUSE IF NOT EXISTS TEST_WH
    WAREHOUSE_SIZE   = SMALL
    AUTO_SUSPEND     = 60
    AUTO_RESUME      = TRUE
    COMMENT          = 'CI/CD workloads for test environment';

CREATE WAREHOUSE IF NOT EXISTS PROD_WH
    WAREHOUSE_SIZE   = MEDIUM
    AUTO_SUSPEND     = 120
    AUTO_RESUME      = TRUE
    COMMENT          = 'CI/CD workloads for prod environment';

-- ============================================================
-- CI/CD roles (one per environment, least-privilege)
-- ============================================================
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS CICD_DEV_ROLE;
CREATE ROLE IF NOT EXISTS CICD_TEST_ROLE;
CREATE ROLE IF NOT EXISTS CICD_PROD_ROLE;

-- Allow SYSADMIN to manage these roles
GRANT ROLE CICD_DEV_ROLE  TO ROLE SYSADMIN;
GRANT ROLE CICD_TEST_ROLE TO ROLE SYSADMIN;
GRANT ROLE CICD_PROD_ROLE TO ROLE SYSADMIN;

-- ============================================================
-- Warehouse grants
-- ============================================================
GRANT USAGE ON WAREHOUSE DEV_WH  TO ROLE CICD_DEV_ROLE;
GRANT USAGE ON WAREHOUSE TEST_WH TO ROLE CICD_TEST_ROLE;
GRANT USAGE ON WAREHOUSE PROD_WH TO ROLE CICD_PROD_ROLE;

-- ============================================================
-- Database grants
-- ============================================================
GRANT USAGE ON DATABASE MYPROJECT_DEV  TO ROLE CICD_DEV_ROLE;
GRANT USAGE ON DATABASE MYPROJECT_TEST TO ROLE CICD_TEST_ROLE;
GRANT USAGE ON DATABASE MYPROJECT_PROD TO ROLE CICD_PROD_ROLE;

-- Dev: the CI pipeline creates isolated schemas per developer at runtime,
-- so CICD_DEV_ROLE needs CREATE SCHEMA on the database.
GRANT CREATE SCHEMA ON DATABASE MYPROJECT_DEV TO ROLE CICD_DEV_ROLE;

-- ============================================================
-- Schema grants – test and prod use the PUBLIC schema
-- ============================================================
GRANT USAGE             ON SCHEMA MYPROJECT_DEV.PUBLIC TO ROLE CICD_DEV_ROLE;
GRANT CREATE TABLE      ON SCHEMA MYPROJECT_DEV.PUBLIC TO ROLE CICD_DEV_ROLE;
GRANT CREATE VIEW       ON SCHEMA MYPROJECT_DEV.PUBLIC TO ROLE CICD_DEV_ROLE;
GRANT CREATE PROCEDURE  ON SCHEMA MYPROJECT_DEV.PUBLIC TO ROLE CICD_DEV_ROLE;

GRANT USAGE             ON SCHEMA MYPROJECT_TEST.PUBLIC TO ROLE CICD_TEST_ROLE;
GRANT CREATE TABLE      ON SCHEMA MYPROJECT_TEST.PUBLIC TO ROLE CICD_TEST_ROLE;
GRANT CREATE VIEW       ON SCHEMA MYPROJECT_TEST.PUBLIC TO ROLE CICD_TEST_ROLE;
GRANT CREATE PROCEDURE  ON SCHEMA MYPROJECT_TEST.PUBLIC TO ROLE CICD_TEST_ROLE;

GRANT USAGE             ON SCHEMA MYPROJECT_PROD.PUBLIC TO ROLE CICD_PROD_ROLE;
GRANT CREATE TABLE      ON SCHEMA MYPROJECT_PROD.PUBLIC TO ROLE CICD_PROD_ROLE;
GRANT CREATE VIEW       ON SCHEMA MYPROJECT_PROD.PUBLIC TO ROLE CICD_PROD_ROLE;
GRANT CREATE PROCEDURE  ON SCHEMA MYPROJECT_PROD.PUBLIC TO ROLE CICD_PROD_ROLE;

-- ============================================================
-- Service account users are created in scripts/admin_auth_setup.sql
-- (Feature 8) after the RSA key pairs have been generated.
-- ============================================================
