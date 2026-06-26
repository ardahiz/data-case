-- Fact: Cohort-based Net Revenue Retention (NRR)
-- Unique Key: cohort_month + revenue_month + months_since_cohort
-- Purpose: Aggregate NRR metrics by cohort and reporting month
-- Key Metrics:
--   - NRR: (current_mrr / starting_mrr) - includes churn, expansion, and contraction
--   - Gross Revenue Retention: (retained_mrr / starting_mrr) - churn-adjusted, excludes expansion
--   - cohort_customer_count: Total customers in cohort at first revenue month
--   - active_customer_count: Customers with positive MRR in reporting month
--   - churned_customer_count: Customers with zero or negative MRR in reporting month
with customer_cohort_months as (
    select * from {{ ref('int_customer_cohort_months') }}
)

select
    ccm.cohort_month,
    ccm.revenue_month,
    ccm.months_since_cohort,
    count(distinct ccm.customer_id) as cohort_customer_count,
    count(distinct case when ccm.current_mrr_eur > 0 then ccm.customer_id end) as active_customer_count,
    count(distinct case when ccm.current_mrr_eur <= 0 then ccm.customer_id end) as churned_customer_count,
    sum(ccm.starting_mrr_eur) as starting_mrr_eur,
    sum(ccm.current_mrr_eur) as current_mrr_eur,
    sum(ccm.retained_mrr_eur) as retained_mrr_eur,
    sum(ccm.expansion_mrr_eur) as expansion_mrr_eur,
    sum(ccm.contraction_mrr_eur) as contraction_mrr_eur,
    sum(ccm.churned_mrr_eur) as churned_mrr_eur,
    sum(ccm.current_mrr_eur) / nullif(sum(ccm.starting_mrr_eur), 0) as nrr,
    sum(ccm.retained_mrr_eur) / nullif(sum(ccm.starting_mrr_eur), 0) as gross_revenue_retention
from customer_cohort_months as ccm
group by
    ccm.cohort_month,
    ccm.revenue_month,
    ccm.months_since_cohort
