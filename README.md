# Snowflake CI/CD Reference Template

A ready-to-use template for deploying Snowflake objects and dbt models via Azure Pipelines. Includes isolated developer schemas, per-environment credentials, and manual approval gates for test and prod.

## Tech stack

- **Snowflake CLI** — deploys native objects (tables, views, stored procedures)
- **dbt-snowflake** — runs transformations and tests on top of native objects
- **Azure Pipelines** — CI/CD orchestration
- **GitHub** — source control

## Repo structure

```
snowflake/
├── tables/                   CREATE OR REPLACE table DDL
├── views/                    CREATE OR REPLACE view DDL
├── stored_procedures/        CREATE OR REPLACE procedure DDL
└── snowflake.yml             Snowflake CLI project config (env var templated)

dbt/
├── models/
│   ├── staging/              Staging models sourced from native Snowflake tables
│   └── marts/                Final analytical mart models
├── dbt_project.yml
└── profiles.yml              All three targets (dev/test/prod) via env vars

.azure/
└── azure-pipelines.yml       Single pipeline: CI + CD_Test + CD_Prod stages

scripts/
├── deploy.sh                 Deploys native objects in order: tables → views → stored_procedures
├── smoke_test.sql            Post-deploy smoke tests run via snow sql
├── generate_keys.sh          Generates RSA key pairs for all three service accounts
├── admin_setup.sql           One-time SYSADMIN setup (databases, warehouses, roles, grants)
└── admin_auth_setup.sql      One-time SECURITYADMIN setup (service accounts, RSA keys, ADO variable group reference)
```

## Environments

| | Dev | Test | Prod |
|---|---|---|---|
| Database | `MYPROJECT_DEV` | `MYPROJECT_TEST` | `MYPROJECT_PROD` |
| Schema | `<GIT_USERNAME>` (per developer) | `PUBLIC` | `PUBLIC` |
| Warehouse | `DEV_WH` (XS) | `TEST_WH` (S) | `PROD_WH` (M) |
| Role | `CICD_DEV_ROLE` | `CICD_TEST_ROLE` | `CICD_PROD_ROLE` |
| Service account | `CICD_DEV_SVC` | `CICD_TEST_SVC` | `CICD_PROD_SVC` |
| ADO variable group | `snowflake-dev` | `snowflake-test` | `snowflake-prod` |
| Trigger | every branch push / PR | merge to `test` branch | merge to `main` branch |
| Approval gate | none | required | required |

## Pipeline behaviour

```
push to any branch / PR to main or test
│
└─► CI stage (always runs)
      install tooling
      derive dev schema from committer email  (e.g. john.doe@ → JOHN_DOE)
      CREATE SCHEMA IF NOT EXISTS MYPROJECT_DEV.JOHN_DOE
      deploy.sh  →  tables → views → stored_procedures
      smoke_test.sql  →  DESCRIBE + SELECT LIMIT 0 + CALL
      dbt run  →  staging models, then mart
      dbt test  →  not_null, unique, accepted_values, relationships

merge to `test` branch
│
└─► CI  →  [approval gate]  →  CD_Test stage
                                  deploy.sh (MYPROJECT_TEST.PUBLIC)
                                  dbt run + dbt test (target=test)

merge to `main` branch
│
└─► CI  →  [approval gate]  →  CD_Prod stage
                                  deploy.sh (MYPROJECT_PROD.PUBLIC)
                                  dbt run + dbt test (target=prod)
```

---

## Setup guide

### Prerequisites

- Snowflake account with SYSADMIN and SECURITYADMIN access
- Azure DevOps project with Pipelines enabled
- `openssl` available locally
- GitHub repository (fork or copy this template)

### Step 1 — Rename the project

Replace `MYPROJECT` with your actual project name in the following files before running anything:

- `scripts/admin_setup.sql` — database, warehouse, and role names
- `scripts/admin_auth_setup.sql` — user defaults and comments
- `dbt/dbt_project.yml` — `name:` field and profile name
- `dbt/profiles.yml` — top-level profile key

### Step 2 — Provision Snowflake resources

Run `scripts/admin_setup.sql` in a Snowflake worksheet as **SYSADMIN / SECURITYADMIN**. This creates:

- Three databases (`MYPROJECT_DEV`, `MYPROJECT_TEST`, `MYPROJECT_PROD`)
- Three auto-suspending warehouses (`DEV_WH`, `TEST_WH`, `PROD_WH`)
- Three least-privilege CI/CD roles with appropriate grants

### Step 3 — Generate RSA key pairs

```bash
bash scripts/generate_keys.sh
```

This writes six files to `.keys/` (git-ignored):

```
.keys/rsa_key_dev.p8    rsa_key_dev.pub
.keys/rsa_key_test.p8   rsa_key_test.pub
.keys/rsa_key_prod.p8   rsa_key_prod.pub
```

### Step 4 — Create Snowflake service accounts

1. Open `scripts/admin_auth_setup.sql`.
2. For each environment, replace the `RSA_PUBLIC_KEY` placeholder with the key body from the matching `.pub` file — the lines between (but not including) `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`.
3. Run the script as **SECURITYADMIN**.

### Step 5 — Create ADO variable groups

In Azure DevOps go to **Pipelines → Library** and create three variable groups. The required variables for each group are documented at the bottom of `scripts/admin_auth_setup.sql`.

| Variable | Description | Secret |
|---|---|---|
| `SNOWFLAKE_ACCOUNT` | Account identifier (e.g. `xy12345.us-east-1`) | No |
| `SNOWFLAKE_USER` | Service account username | No |
| `SNOWFLAKE_PRIVATE_KEY` | Full content of the `.p8` file | **Yes** |
| `SNOWFLAKE_ROLE` | CI/CD role for this environment | No |
| `SNOWFLAKE_DATABASE` | Target database | No |
| `SNOWFLAKE_SCHEMA` | `PUBLIC` (overridden at runtime for dev) | No |
| `SNOWFLAKE_WAREHOUSE` | Target warehouse | No |

After creating the groups, delete the `.keys/` directory or store the private key files in a secrets manager.

### Step 6 — Configure ADO Environments and approval gates

In Azure DevOps go to **Pipelines → Environments** and create two environments:

- `snowflake-test`
- `snowflake-prod`

On each environment, open **Approvals and checks → Approvals** and add the required approvers. The pipeline will pause at each gate before deploying to that environment.

### Step 7 — Register the pipeline

In Azure DevOps go to **Pipelines → New Pipeline**, connect your GitHub repository, and select **Existing Azure Pipelines YAML file**. Point it at `.azure/azure-pipelines.yml`.

### Step 8 — Local development setup

Copy `snowflake/config.toml.example` to `~/.snowflake/config.toml` and fill in your values. Use the `dev` connection for day-to-day development.

```bash
cp snowflake/config.toml.example ~/.snowflake/config.toml
# edit ~/.snowflake/config.toml
```

Your isolated dev schema (`MYPROJECT_DEV.<YOUR_USERNAME>`) is created automatically on your first pipeline run.

---

## Adapting the template

| What to change | Where |
|---|---|
| Project name | `scripts/admin_setup.sql`, `scripts/admin_auth_setup.sql`, `dbt/dbt_project.yml`, `dbt/profiles.yml` |
| Snowflake objects | `snowflake/tables/`, `snowflake/views/`, `snowflake/stored_procedures/` |
| dbt models | `dbt/models/staging/`, `dbt/models/marts/` |
| dbt sources | `dbt/models/staging/sources.yml` — update `database` and `schema` env vars if needed |
| Smoke tests | `scripts/smoke_test.sql` — add DESCRIBE / CALL for your objects |
| Warehouse sizes | `scripts/admin_setup.sql` — adjust `WAREHOUSE_SIZE` per environment |
