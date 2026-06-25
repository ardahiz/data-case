with subscription_monthly_revenue as (
    select * from {{ ref('int_subscription_monthly_revenue') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    subscription_monthly_revenue.customer_id,
    customers.company_name,
    customers.region,
    customers.segment,
    customers.signup_date,
    subscription_monthly_revenue.invoice_month,
    sum(subscription_monthly_revenue.actual_mrr_eur) as actual_mrr_eur,
    sum(subscription_monthly_revenue.signed_mrr_eur) as signed_mrr_eur,
    count(distinct subscription_monthly_revenue.subscription_id) as active_subscription_count,
    sum(subscription_monthly_revenue.invoice_count) as invoice_count
from subscription_monthly_revenue
left join customers
    on subscription_monthly_revenue.customer_id = customers.customer_id
group by
    subscription_monthly_revenue.customer_id,
    customers.company_name,
    customers.region,
    customers.segment,
    customers.signup_date,
    subscription_monthly_revenue.invoice_month
