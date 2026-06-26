-- Intermediate: Customer cohort months with revenue tracking
-- Unique Key: customer_id + cohort_month + revenue_month
-- Purpose: Track revenue changes (retained, expanded, contracted, churned) for each customer in each cohort month
-- Note: Includes all months from cohort_month onwards within the data range; missing months = 0 revenue
with customer_cohorts as (
    select * from {{ ref('int_customer_cohorts') }}
),

customer_monthly_revenue as (
    select * from {{ ref('int_customer_monthly_revenue') }}
),

month_spine as (
    select cast(month_value as date) as revenue_month
    from generate_series(
        (select min(cohort_month) from customer_cohorts),
        (select max(invoice_month) from customer_monthly_revenue),
        interval 1 month
    ) as months(month_value)
)

select
    cc.customer_id,
    cc.company_name,
    cc.region,
    cc.segment,
    cc.signup_date,
    cc.cohort_month,
    ms.revenue_month,
    date_diff('month', cc.cohort_month, ms.revenue_month) as months_since_cohort,
    cc.starting_mrr_eur,
    coalesce(cmr.actual_mrr_eur, 0) as actual_mrr_eur,
    greatest(coalesce(cmr.actual_mrr_eur, 0), 0) as current_mrr_eur,

    least(greatest(coalesce(cmr.actual_mrr_eur, 0), 0), cc.starting_mrr_eur) as retained_mrr_eur,
    greatest(greatest(coalesce(cmr.actual_mrr_eur, 0), 0) - cc.starting_mrr_eur, 0) as expansion_mrr_eur,
    case
        when greatest(coalesce(cmr.actual_mrr_eur, 0), 0) > 0
            and greatest(coalesce(cmr.actual_mrr_eur, 0), 0) < cc.starting_mrr_eur
            then cc.starting_mrr_eur - greatest(coalesce(cmr.actual_mrr_eur, 0), 0)
        else 0
    end as contraction_mrr_eur,
    case
        when greatest(coalesce(cmr.actual_mrr_eur, 0), 0) <= 0
            then cc.starting_mrr_eur
        else 0
    end as churned_mrr_eur
from customer_cohorts as cc
inner join month_spine as ms
    on ms.revenue_month >= cc.cohort_month
left join customer_monthly_revenue as cmr
    on cc.customer_id = cmr.customer_id
    and ms.revenue_month = cmr.invoice_month
