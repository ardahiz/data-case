with source as (
    select * from {{ ref('billing_invoices') }}
),

typed as (
    select
        trim(invoice_id) as invoice_id,
        trim(customer_id) as customer_id,
        trim(subscription_id) as subscription_id,
        cast(invoice_month as date) as invoice_month,
        cast(actual_amount_eur as double) as actual_amount_eur
    from source
),

deduped as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by invoice_id
                order by customer_id, subscription_id, invoice_month, actual_amount_eur
            ) as row_number
        from typed
    )
    where row_number = 1
)

select
    invoice_id,
    customer_id,
    subscription_id,
    invoice_month,
    actual_amount_eur
from deduped
