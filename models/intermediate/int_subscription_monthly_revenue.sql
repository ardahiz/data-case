-- Intermediate: Monthly subscription revenue
-- Unique Key: customer_id + subscription_id + invoice_month
-- Purpose: multiple invoices for the same subscription/month is summed
with invoices as (
    select * from {{ ref('stg_billing_invoices') }}
),

subscriptions as (
    select * from {{ ref('stg_crm_subscriptions') }}
)

select
    i.customer_id,
    i.subscription_id,
    i.invoice_month,
    s.plan,
    s.signed_mrr_eur,
    sum(i.actual_amount_eur) as actual_mrr_eur,
    count(*) as invoice_count
from invoices as i
left join subscriptions as s
    on i.subscription_id = s.subscription_id
group by
    i.customer_id,
    i.subscription_id,
    i.invoice_month,
    s.plan,
    s.signed_mrr_eur
