# Interview And Stakeholder Brief

## Audience

This document is for presentation preparation, reviewer context, and stakeholder-friendly explanation. It is broader than `DECISIONS.md` and easier to scan before a live walkthrough.

## One-Minute Summary

I built a local dbt model that calculates cohort-based Net Revenue Retention from CRM customer data, CRM subscription data, and billing invoices. The model uses actual billing data as the revenue source of truth, assigns cohorts based on first positive billed revenue month, aggregates revenue to customer-month before calculating retention, and exposes a final cohort-month NRR mart.

## What Problem This Solves

The company needs a trusted way to answer:

For customers who joined in a given period, how does their recurring revenue evolve over the following months?

This matters commercially because NRR shows whether existing customers are expanding, contracting, or churning after acquisition.

The pipeline is relevant to this question because it fixes the customer cohort first, then follows that same set of customers across later billing months. Net-new customers who start in later months enter their own cohorts rather than inflating an earlier cohort's NRR.

## Key Design Choices

### Billing Actuals As Revenue Source

I used invoices as the source of truth because NRR is a revenue retention metric. CRM signed MRR is useful context, but invoices reflect what was actually billed, including credits, discounts, partial months, and billing adjustments. For retention math, I preserve the raw billed amount and also use a non-negative current revenue value so refund or credit months are treated as zero retained recurring revenue rather than negative retention.

### Customer-Month As The Core Grain

The data has multiple subscriptions per customer. If NRR were calculated directly at subscription level, customers with multiple contracts or plan changes could be double counted. Aggregating to customer-month first makes the metric customer-centric.

### Customer Data Quality Example

Because the raw customer seed contained duplicate `customer_id` rows, the staging layer deduplicates customers on `customer_id` as a data quality safeguard. This keeps the final cohort assignment and retention analysis customer-centric and prevents duplicate customer records from corrupting the cohort grain.

### First Positive Invoice Month As Cohort Month

I chose first positive actual billed revenue month as `cohort_month`. This avoids assigning cohorts based on CRM signup dates or contract dates that may not reflect revenue starting. It also avoids credit-only first months creating negative starting MRR.

### Missing Months As Zero Revenue

For each cohort customer, the model creates a complete monthly panel from cohort month to the latest observed billing month. If there is no invoice in a later month, current revenue is zero. This makes churn and billing gaps visible.

### README As Original Case Instructions

I treated `README.md` as the original case prompt rather than the solution write-up. The implemented solution details live in `DECISIONS.md` and this brief, so the project instructions remain untouched while the modeling choices are documented separately.

## Date Semantics

This case is tricky because several date fields sound similar but answer different questions.

| Date | Meaning | How I Used It |
| --- | --- | --- |
| `signup_date` | When customer was created or signed up in CRM | Customer context |
| `start_date` | Subscription contract start date | Contract context |
| `end_date` | Subscription contract end date | Contract context |
| `invoice_month` | Month actual revenue was billed | Revenue source |
| `cohort_month` | First positive actual billing month | Cohort assignment |
| `revenue_month` | Month measured in the retention curve | Final NRR grain |

The important principle is that a date should be named for its business meaning, not just its datatype.

## Metric Definitions

| Metric | Definition |
| --- | --- |
| Starting MRR | Customer revenue in the cohort month |
| Signed current revenue | Raw customer revenue in the measured revenue month |
| Current MRR | Non-negative customer revenue used for retention math |
| NRR | Current MRR divided by starting MRR for the original cohort |
| Retained MRR | Current revenue up to the customer's starting MRR |
| Expansion MRR | Current revenue above starting MRR |
| Contraction MRR | Lost revenue when current revenue is positive but below starting MRR |
| Churned MRR | Starting MRR when current revenue is zero or negative |
| GRR | Retained MRR divided by starting MRR |

## Model Structure

Pipeline summary:

```text
seeds
  dim_customers
  crm_subscriptions
  billing_invoices
    -> source wrapper models
    -> staging cleanup and deduplication
    -> intermediate revenue and cohort models
    -> fct_cohort_nrr mart
```

### Staging

Staging models clean raw data:

- type casting
- deduplication
- identifier trimming
- status/category normalization

### Intermediate

Intermediate models define reusable business logic:

- subscription-month actual revenue
- customer-month actual revenue
- customer cohort assignment
- complete customer cohort-month panel

### Mart

The mart exposes final stakeholder-facing NRR:

- `fct_cohort_nrr`
- grain: one row per `cohort_month` and `revenue_month`

It includes cohort size, active and churned customer counts, starting MRR, current MRR, retained MRR, expansion MRR, contraction MRR, churned MRR, NRR, and gross revenue retention.

## Testing Approach

I kept tests separate from transformation SQL because dbt tests are designed to return failing rows and run consistently in CI or before PR submission.

Tests cover:

- non-null keys
- uniqueness at expected grains
- relationships across customers, subscriptions, and invoices
- no duplicate subscription-month rows
- no duplicate customer-month rows
- positive starting MRR for cohorts
- NRR ratio correctness

Additional checks I would add in a production version:

- invoice `customer_id` matches the customer on the joined subscription
- explicit accepted-values tests for normalized `region`, `segment`, and `subscription_status`
- seed column types pinned in `seeds/properties.yml` instead of relying on inference

## Logic Review

Overall, the pipeline is logically aligned with cohort NRR. The most important design choices are customer-month aggregation before cohort logic, first positive actual billing month as the cohort date, and a complete month panel so missing invoices become observable churn or billing gaps.

The main caveats are deliberate rather than accidental:

- Negative invoices remain in signed current revenue; retention math clamps that value to zero.
- For decomposition, non-positive current revenue is treated as churned MRR, which is simple and explainable but may mix true churn with credits.
- CRM `status` and `end_date` are not used as the primary churn source because billing actuals are the chosen source of truth.
- The model answers monthly realized revenue retention, not contracted MRR retention.

## How To Validate Before Pushing

In Codespaces or any local environment:

```bash
source .venv/bin/activate
export DBT_PROFILES_DIR=$(pwd)
dbt seed --full-refresh
dbt build
dbt show --select fct_cohort_nrr --limit 20
```

`dbt build` is the best pre-push command because it runs seeds, models, and tests together in dependency order.

## How To Inspect Results

Use:

```bash
dbt show --select fct_cohort_nrr --limit 20
```

Or query the DuckDB file directly if needed:

```bash
python -c "import duckdb; con=duckdb.connect('nelly_nrr.duckdb'); print(con.sql('select * from main_marts.fct_cohort_nrr limit 20').fetchdf())"
```

The schema name may differ by target, so `dbt show` is the safer first option.

## Likely Interview Questions

### Why did you use billing instead of signed MRR?

Because NRR is about realized revenue retention. Signed MRR is contract intent, but invoices show actual customer billing.

### Why not use signup date as the cohort?

Signup date is a CRM lifecycle date, not necessarily a revenue date. A customer should enter an NRR cohort when revenue begins.

### Why customer-month instead of subscription-month?

NRR is usually customer retention, not contract retention. Customer-month avoids double counting customers with multiple subscriptions.

### How did you treat churn?

If a cohort customer has no positive revenue in a later month, their current revenue is zero or negative, and their starting MRR is counted as churned MRR for decomposition.

### How would you change the model live?

I would first identify which layer owns the requested logic. For example, cohort changes belong in `int_customer_cohorts`; final grouping changes belong in `fct_cohort_nrr`. Then I would rebuild and test downstream models.

## Live Change Examples

### Add Segment-Level NRR

Edit `fct_cohort_nrr`:

- include `segment`
- add it to `select`
- add it to `group by`

Then run:

```bash
dbt run --select +fct_cohort_nrr
dbt test --select +fct_cohort_nrr
```

### Change Cohort Definition

Edit `int_customer_cohorts` and update how `cohort_month` is assigned.

Then run:

```bash
dbt run --select int_customer_cohorts+ 
dbt test --select int_customer_cohorts+
```

### Change Revenue Source

Edit the intermediate revenue model where customer-month revenue is calculated. Then update documentation and tests because this changes the metric definition.

## Trade-Offs

I did not build a dashboard because the case asks for the model. I also kept the handling of credits simple: actual revenue remains in NRR, while decomposition fields are bounded for interpretability. With more time, I would add reconciliation analysis between signed and actual MRR and investigate negative billing months with finance.
