# Decisions & Assumptions

_Short summary of key decisions that underpin the cohort-based NRR model._

## NRR definition & grain

- Cohort: each customer's first month with positive billed revenue (cohort_month).

- `NRR = sum(current_mrr_eur) / sum(starting_mrr_eur)`

- Final grain: one row per `cohort_month` × `revenue_month` (cohort-level NRR derived
	from customer-month aggregates).

## Signed vs. actual revenue

- Revenue basis: billing invoices (`actual_amount_eur`) are the source of truth for NRR.
- CRM `signed` MRR is retained for context and validation but not used in NRR calculations.

## Handling ambiguous / messy records

- Staging normalizes and deduplicates raw seeds.
- For NRR math, if a `current_mrr` of a month<0, it's capped as 0. 
- In invoice table the `invoice_month` is sparse. During the `customer-month` aggregation, I used a date spine and treated missing rows as 0 realized revenue.
- There are multiple subscriptions per customer. I worked with first `subscription-month` then `customer-month` level to avoid double counting


## Modeling approach

- Layering: `staging` cleans and dedups seeds → `intermediate` builds `subscription-month`
	then `customer-month` aggregates → `mart` computes cohort NRR.
- Business logic lives primarily in intermediate models (aggregation, de-duplication, churn rules);
	the mart performs cohort-level summarization and NRR ratio calculation.

## Trade-offs & what you'd improve with more time

- stg tables are deduped but they are prone to silent data failures. 
- Reconcilation regions: Country grouping is odd with DACH region but DE CH AT as countries.
- I used churn inference from billing gaps. It is pragmatic but imperfect. More reliable churn detection would come from crm or invoice reason codes if kept.
- With more time: I'd dig deeper on tests, for example I would add conflict testing with warning severity and remove dedup on customer_id level. Also I'd find better naming for the kpis & tables. 

More context and rationale are in [docs/interview_and_stakeholder_brief.md](docs/interview_and_stakeholder_brief.md#L1).
