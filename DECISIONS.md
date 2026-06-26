# Decisions & Assumptions

_Short summary of key decisions that underpin the cohort-based NRR model._

## NRR definition & grain

- Cohort: each customer's first month with positive billed revenue (cohort_month).
- NRR: measured as

- `NRR = sum(current_mrr_eur) / sum(starting_mrr_eur)`

- Final grain: one row per `cohort_month` × `revenue_month` (cohort-level NRR derived
	from customer-month aggregates).

## Signed vs. actual revenue

- Revenue basis: billing invoices (`actual_amount_eur`) are the source of truth for NRR.
- CRM `signed` MRR is retained for context and validation but not used in NRR calculations.

## Handling ambiguous / messy records

- Staging normalizes and deduplicates raw seeds; invoice-level negatives are retained as realized billed
	amounts and propagated into intermediate/customer-month aggregates (credit classification out of scope).
- For retention math, NRR uses a non-negative current revenue value so refund/credit months are treated as
	zero retained recurring revenue rather than negative retention.
- Missing months after cohort entry are treated as zero realized revenue.
- Multiple subscriptions per customer are rolled up to `customer-month` to avoid double counting; churn
	is inferred from billing gaps or sustained non-positive revenue rather than CRM lifecycle flags.

## Modeling approach

- Layering: `staging` cleans and harmonizes seeds → `intermediate` builds subscription-month
	then `customer-month` aggregates → `mart` computes cohort NRR.
- Business logic lives primarily in intermediate models (aggregation, de-duplication, churn rules);
	the mart performs cohort-level summarization and NRR ratio calculation.

## Trade-offs & what you'd improve with more time

- We keep negative invoices as realized revenue to reflect billed activity; a fuller credit/adjustment
	classification would improve accuracy.
- Churn inference from billing gaps is pragmatic but imperfect; more reliable churn detection would
	come from invoice reason codes or payment status reconciliation.
- With more time: reconcile signed vs billed amounts systematically, add sensitivity tests for
	cohort definitions, and build a small adjustments layer to isolate non-recurring credits.

More context and rationale are in [docs/interview_and_stakeholder_brief.md](docs/interview_and_stakeholder_brief.md#L1).
