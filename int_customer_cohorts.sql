with customer_monthly_revenue as (
    select * from {{ ref('int_customer_monthly_revenue') }}
),

first_positive_revenue_month as (
    select
        customer_id,
        min(invoice_month) as cohort_month
    from customer_monthly_revenue
    where actual_mrr_eur > 0
    group by customer_id
)

select
    customer_monthly_revenue.customer_id,
    customer_monthly_revenue.company_name,
    customer_monthly_revenue.region,
    customer_monthly_revenue.segment,
    customer_monthly_revenue.signup_date,
    first_positive_revenue_month.cohort_month,
    customer_monthly_revenue.actual_mrr_eur as starting_mrr_eur
from first_positive_revenue_month
inner join customer_monthly_revenue
    on first_positive_revenue_month.customer_id = customer_monthly_revenue.customer_id
    and first_positive_revenue_month.cohort_month = customer_monthly_revenue.invoice_month
