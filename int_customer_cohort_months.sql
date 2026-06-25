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
    customer_cohorts.customer_id,
    customer_cohorts.company_name,
    customer_cohorts.region,
    customer_cohorts.segment,
    customer_cohorts.signup_date,
    customer_cohorts.cohort_month,
    month_spine.revenue_month,
    date_diff('month', customer_cohorts.cohort_month, month_spine.revenue_month) as months_since_cohort,
    customer_cohorts.starting_mrr_eur,
    coalesce(customer_monthly_revenue.actual_mrr_eur, 0) as current_mrr_eur,
    least(greatest(coalesce(customer_monthly_revenue.actual_mrr_eur, 0), 0), customer_cohorts.starting_mrr_eur) as retained_mrr_eur,
    greatest(coalesce(customer_monthly_revenue.actual_mrr_eur, 0) - customer_cohorts.starting_mrr_eur, 0) as expansion_mrr_eur,
    case
        when coalesce(customer_monthly_revenue.actual_mrr_eur, 0) > 0
            and coalesce(customer_monthly_revenue.actual_mrr_eur, 0) < customer_cohorts.starting_mrr_eur
            then customer_cohorts.starting_mrr_eur - coalesce(customer_monthly_revenue.actual_mrr_eur, 0)
        else 0
    end as contraction_mrr_eur,
    case
        when coalesce(customer_monthly_revenue.actual_mrr_eur, 0) <= 0
            then customer_cohorts.starting_mrr_eur
        else 0
    end as churned_mrr_eur
from customer_cohorts
inner join month_spine
    on month_spine.revenue_month >= customer_cohorts.cohort_month
left join customer_monthly_revenue
    on customer_cohorts.customer_id = customer_monthly_revenue.customer_id
    and month_spine.revenue_month = customer_monthly_revenue.invoice_month
