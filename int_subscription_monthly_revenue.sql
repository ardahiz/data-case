with invoices as (
    select * from {{ ref('stg_billing_invoices') }}
),

subscriptions as (
    select * from {{ ref('stg_crm_subscriptions') }}
)

select
    invoices.customer_id,
    invoices.subscription_id,
    invoices.invoice_month,
    subscriptions.plan,
    subscriptions.signed_mrr_eur,
    sum(invoices.actual_amount_eur) as actual_mrr_eur,
    count(*) as invoice_count
from invoices
left join subscriptions
    on invoices.subscription_id = subscriptions.subscription_id
group by
    invoices.customer_id,
    invoices.subscription_id,
    invoices.invoice_month,
    subscriptions.plan,
    subscriptions.signed_mrr_eur
