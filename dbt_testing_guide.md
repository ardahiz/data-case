# dbt Testing Guide

## Audience

This document is for contributors who are familiar with SQL assertions in tools like Dataform but newer to dbt's testing style.

## How dbt Tests Work

In dbt, a test passes when its generated query returns zero rows. A test fails when the query returns one or more rows.

There are two main test styles in this project:

1. Generic tests declared in YAML files
2. Singular SQL tests stored in the `tests/` folder

## Generic YAML Tests

YAML tests live in files such as:

- `models/staging/schema.yml`
- `models/intermediate/schema.yml`
- `models/marts/schema.yml`

These files describe models and columns, and they tell dbt which built-in tests to generate.

Example:

```yml
models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique
```

This tells dbt to generate SQL checks for:

- `customer_id` is never null
- `customer_id` is unique

You do not write the SQL for these tests manually. dbt generates it.

## Relationship Tests

Relationship tests check referential integrity.

Example:

```yml
- name: customer_id
  tests:
    - relationships:
        to: ref('stg_customers')
        field: customer_id
```

This means every `customer_id` in the current model must exist in `stg_customers.customer_id`.

This is similar to asserting that invoice customer IDs have a valid parent customer.

## Singular SQL Tests

Singular tests are manually written SQL files in the `tests/` folder.

Example:

```sql
select
    customer_id,
    invoice_month,
    count(*) as row_count
from {{ ref('int_customer_monthly_revenue') }}
group by customer_id, invoice_month
having count(*) > 1
```

This test fails only if duplicate customer-month rows exist.

The rule is:

- zero rows returned = pass
- one or more rows returned = fail

## Why Tests Are Separate From Model SQL

Keep transformation SQL and assertion SQL separate.

Model SQL should produce business tables and views.

Test SQL should validate assumptions about those tables and views.

This makes the project easier to review, lets `dbt test` run all checks consistently, and avoids mixing production transformations with validation-only logic.

## Main Commands

Run models only:

```bash
dbt run
```

Run tests only:

```bash
dbt test
```

Run seeds, models, and tests together:

```bash
dbt build
```

Inspect a model result:

```bash
dbt show --select fct_cohort_nrr --limit 20
```

## Recommended Pre-Push Workflow

Use this before committing or pushing:

```bash
export DBT_PROFILES_DIR=$(pwd)
dbt seed --full-refresh
dbt build
dbt show --select fct_cohort_nrr --limit 20
```

If `dbt build` fails, inspect the failing model or test, fix it, and run `dbt build` again.
