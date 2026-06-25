# Agent Rules

## Audience

This document is for AI agents and data contributors working in this repository. It is the durable alignment layer: when the pipeline or metric logic changes, update this file so future work stays consistent.

## Rule 1: Keep Documentation Current

Whenever a change affects metric logic, grain, date semantics, source-of-truth assumptions, or model ownership, update the relevant documentation in the same PR.

At minimum, check whether these files need updates:

- `DECISIONS.md`
- `docs/agent_build_plan.md`
- `docs/interview_and_stakeholder_brief.md`
- dbt `schema.yml` descriptions

## Rule 2: State Every Model Grain

Every important model should have an explicit grain documented in either the model description or nearby documentation.

Examples:

- staging customer model: one row per customer
- customer monthly revenue model: one row per customer per invoice month
- final NRR mart: one row per cohort month per revenue month

## Rule 3: Keep Layer Responsibilities Separate

Staging models should clean raw source data only.

Intermediate models should contain reusable business logic.

Mart models should expose final stakeholder-facing metrics.

Do not put all metric logic directly into a final mart if it can be cleanly expressed at a reusable intermediate grain.

## Rule 4: Define Dates Explicitly

Do not use generic names like `date` or `month` for derived analytical concepts.

Prefer explicit names:

- `signup_date`
- `start_date`
- `end_date`
- `invoice_month`
- `cohort_month`
- `revenue_month`
- `months_since_cohort`

If a date field changes meaning, update documentation and downstream model descriptions.

## Rule 5: Use Billing Actuals for NRR Unless Deliberately Changed

The current NRR definition uses `billing_invoices.actual_amount_eur` as the revenue source of truth.

If this changes, update:

- intermediate revenue models
- final NRR model
- metric definitions
- `DECISIONS.md`
- PR description

## Rule 6: Aggregate to Customer-Month Before Cohort Logic

Customers can have multiple subscriptions. NRR should be calculated for customer cohorts, so subscription-level revenue must be aggregated to customer-month before cohort assignment and retention calculations.

## Rule 7: Keep Tests Outside Transformation SQL

Use dbt schema tests and singular SQL tests for assertions. Avoid embedding test-only queries in transformation models.

Transformation SQL should produce business data. Tests should return failing rows when assumptions are violated.

## Rule 8: Validate Before Push

Before pushing or opening a PR, run:

```bash
export DBT_PROFILES_DIR=$(pwd)
dbt seed --full-refresh
dbt build
dbt show --select fct_cohort_nrr --limit 20
```

If a command fails, fix the model or document the unresolved issue before submitting.

## Rule 9: Prefer Small, Reviewable Changes

When making a live or interview change, identify the owning layer first, edit the smallest relevant model, and rebuild downstream dependencies.

Examples:

- cohort definition change: edit `int_customer_cohorts`
- customer-month revenue change: edit `int_customer_monthly_revenue`
- final grouping change: edit `fct_cohort_nrr`

Then run:

```bash
dbt run --select +fct_cohort_nrr
dbt test --select +fct_cohort_nrr
```

## Rule 10: Explain Trade-Offs

When the data is ambiguous, make a clear choice and document it. Do not hide ambiguity inside unexplained SQL.
