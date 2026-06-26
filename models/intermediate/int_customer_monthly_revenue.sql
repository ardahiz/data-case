-- Intermediate: Monthly customer revenue
-- Unique Key: customer_id + invoice_month
-- Purpose: Aggregate revenue per customer per month with customer attributes for cohort analysis
with subscription_monthly_revenue as (
    select * from {{ ref('int_subscription_monthly_revenue') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    smr.customer_id,
    c.company_name,
    c.region,
    c.segment,
    c.signup_date,
    smr.invoice_month,
    sum(smr.actual_mrr_eur) as actual_mrr_eur,
    sum(smr.signed_mrr_eur) as signed_mrr_eur,
    count(distinct smr.subscription_id) as active_subscription_count,
    sum(smr.invoice_count) as invoice_count
from subscription_monthly_revenue as smr
left join customers as c
    on smr.customer_id = c.customer_id
group by
    smr.customer_id,
    c.company_name,
    c.region,
    c.segment,
    c.signup_date,
    smr.invoice_month
