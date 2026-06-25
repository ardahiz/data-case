# Agent Build Plan

## Audience

This document is for an AI coding agent or a data teammate implementing the case. It is intentionally more explicit than `DECISIONS.md` so the builder can make consistent changes without needing verbal context.

## Objective

Build a local dbt + DuckDB project that produces cohort-based Net Revenue Retention (NRR) from three seed sources:

- `dim_customers`
- `crm_subscriptions`
- `billing_invoices`

The final deliverable is a tested dbt mart, not a dashboard or deployed cloud pipeline.

## Business Question

For customers who joined in a given cohort, how does their recurring revenue evolve over the following months, including expansion, contraction, and churn, while excluding net-new customers outside the cohort?

## Source Data Expectations

### `dim_customers`

Customer attributes from CRM.

Known issues to handle:

- inconsistent `region` values such as `DACH`, `dach`, `DE`, `Germany`
- inconsistent `segment` values such as `SMB`, `smb`
- blanks in `region`, `segment`, and `signup_date`

### `crm_subscriptions`

CRM contract/subscription data with signed MRR.

Known issues to handle:

- duplicate subscription rows
- multiple subscriptions per customer
- inconsistent status casing
- missing status values
- status/end-date ambiguity
- signed MRR does not always match actual billing

### `billing_invoices`

Monthly actual invoiced revenue.

Known issues to handle:

- duplicate invoice IDs
- missing invoice months for otherwise active customers
- actual amounts can differ from signed MRR
- actual amounts can be negative due to credits or adjustments

## Metric Definitions

### Cohort Month

The first month in which a customer has positive actual billed revenue.

Rationale: avoids assigning a customer to a cohort based on CRM signup or contract dates when revenue has not started or when the first observed invoice is a credit.

### Revenue Month

The month being measured in the retention curve.

### Starting MRR

The customer's actual billed revenue in their cohort month.

### Current MRR

The customer's actual billed revenue in a later revenue month. If the customer has no invoice in that month, current MRR is zero.

### NRR

Net Revenue Retention:

`sum(current_mrr_eur) / sum(starting_mrr_eur)`

Calculated for the original fixed set of customers in the cohort.

### Retained MRR

The portion of current MRR up to the customer's starting MRR, bounded between zero and starting MRR.

### Expansion MRR

The portion of current MRR above starting MRR.

### Contraction MRR

The positive difference between starting MRR and current MRR when current MRR is above zero but below starting MRR.

### Churned MRR

Starting MRR when current MRR is zero or negative.

## Date Definitions

| Field | Meaning | Use in Model |
| --- | --- | --- |
| `signup_date` | CRM customer signup date | Customer attribute only |
| `start_date` | Subscription contract start date | CRM context, not revenue source |
| `end_date` | Subscription contract end date | CRM context, not primary churn source |
| `invoice_month` | Month actual revenue was billed | Revenue source of truth |
| `cohort_month` | First positive actual billing month | Cohort assignment |
| `revenue_month` | Month being measured after cohort entry | Retention curve |

## Modeling Layers

### Staging

Purpose: clean and type raw source data without embedding final metric logic.

Expected models:

- `stg_customers`
- `stg_crm_subscriptions`
- `stg_billing_invoices`

Responsibilities:

- cast dates and numeric values
- trim identifiers
- normalize casing and categorical values
- deduplicate records by source-system IDs
- preserve useful source fields for downstream context

### Intermediate

Purpose: encode reusable business logic and establish the correct analytical grain.

Expected models:

- `int_subscription_monthly_revenue`
- `int_customer_monthly_revenue`
- `int_customer_cohorts`
- `int_customer_cohort_months`

Responsibilities:

- aggregate invoices to subscription-month
- aggregate subscription revenue to customer-month
- assign each customer to one cohort
- create a complete customer-month panel from cohort month to latest observed billing month
- calculate customer-level retention components

### Mart

Purpose: expose stakeholder-facing cohort NRR.

Expected model:

- `fct_cohort_nrr`

Responsibilities:

- aggregate customer-month retention metrics to cohort-month x revenue-month
- expose final NRR, GRR, revenue components, and customer counts

## Testing Strategy

Use dbt-native tests rather than inline SQL assertions inside transformation models.

YAML tests should cover:

- non-null primary keys
- uniqueness at expected grains
- relationships between invoices, subscriptions, and customers
- non-null final metric fields

Singular SQL tests should cover:

- no duplicate subscription-month rows
- no duplicate customer-month rows
- cohort starting MRR is positive
- NRR ratio equals current MRR divided by starting MRR

## Pre-Push Validation

Run these commands before pushing:

```bash
export DBT_PROFILES_DIR=$(pwd)
dbt seed --full-refresh
dbt build
dbt show --select fct_cohort_nrr --limit 20
```

Use `dbt build` before pushing because it runs seeds, models, and tests together in dependency order.

## Expected Submission

The PR should include:

- layered dbt models
- meaningful tests
- short `DECISIONS.md`
- optional supporting docs for metric definitions and modeling rationale
- a PR description explaining approach, validation, and trade-offs

Do not add a dashboard or cloud deployment unless explicitly requested.
