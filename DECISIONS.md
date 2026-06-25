# Decisions & Assumptions

## NRR Definition & Grain

The final mart, `fct_cohort_nrr`, is at `cohort_month` x `revenue_month` grain. A cohort is defined by each customer's first month with positive actual billed revenue, which avoids assigning customers to a cohort based only on signup dates or credit-only billing months.

NRR is calculated as:

`sum(current_mrr_eur) / sum(starting_mrr_eur)`

for the fixed set of customers in the cohort. Expansion, contraction, and churn are calculated at customer-month level before aggregation. Missing customer-months after cohort entry are treated as zero revenue so churn and temporary billing gaps are visible in the retention curve.

## Signed vs. Actual Revenue

I used billing invoices (`actual_amount_eur`) as the revenue basis for NRR. CRM signed MRR is useful context, but actual invoice data reflects what the customer was truly billed, including partial months, discounts, credits, and mismatches against contract values. Since NRR is a revenue retention metric, billing is the stronger source of truth.

## Handling Ambiguous / Messy Records

I deduplicated exact duplicate CRM subscription and invoice IDs in staging. Customer `region`, `segment`, and subscription status are normalized for consistency. Customers with multiple subscriptions are aggregated to customer-month before NRR logic so plan changes and parallel contracts do not double-count cohorts.

Some actual invoice amounts are negative, likely credits. I keep those amounts in `current_mrr_eur` and therefore in NRR, because they affect realized revenue. For decomposition fields, I bound retained revenue at zero and classify non-positive current revenue as churned for readability.

## Modeling Approach

The project is layered as staging -> intermediate -> mart.

Staging models clean types, normalize dimensions, and deduplicate raw records. Intermediate models aggregate invoices to subscription-month, then customer-month, assign customer cohorts, and create a complete customer-month panel. The mart aggregates customer-level retention metrics into the final cohort NRR table.

## Trade-Offs & What I'd Improve With More Time

I kept the model focused on monthly actual NRR and did not build a dashboard. With more time, I would add reconciliation checks between signed and actual MRR, investigate negative invoice months with finance stakeholders, and add explicit seed column types in `seeds/properties.yml` to avoid relying on inference.
