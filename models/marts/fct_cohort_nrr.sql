with customer_cohort_months as (
    select * from {{ ref('int_customer_cohort_months') }}
)

select
    cohort_month,
    revenue_month,
    months_since_cohort,
    count(distinct customer_id) as cohort_customer_count,
    count(distinct case when current_mrr_eur > 0 then customer_id end) as active_customer_count,
    count(distinct case when current_mrr_eur <= 0 then customer_id end) as churned_customer_count,
    sum(starting_mrr_eur) as starting_mrr_eur,
    sum(current_mrr_eur) as current_mrr_eur,
    sum(retained_mrr_eur) as retained_mrr_eur,
    sum(expansion_mrr_eur) as expansion_mrr_eur,
    sum(contraction_mrr_eur) as contraction_mrr_eur,
    sum(churned_mrr_eur) as churned_mrr_eur,
    sum(current_mrr_eur) / nullif(sum(starting_mrr_eur), 0) as nrr,
    sum(retained_mrr_eur) / nullif(sum(starting_mrr_eur), 0) as gross_revenue_retention
from customer_cohort_months
group by
    cohort_month,
    revenue_month,
    months_since_cohort
