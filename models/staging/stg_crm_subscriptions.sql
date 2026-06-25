with source as (
    select * from {{ ref('src_crm_subscriptions') }}
),

typed as (
    select
        trim(subscription_id) as subscription_id,
        trim(customer_id) as customer_id,
        trim(plan) as plan,
        cast(signed_mrr_eur as double) as signed_mrr_eur,
        cast(nullif(trim(cast(start_date as varchar)), '') as date) as start_date,
        cast(nullif(trim(cast(end_date as varchar)), '') as date) as end_date,
        coalesce(nullif(lower(trim(status)), ''), 'unknown') as subscription_status
    from source
),

deduped as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by subscription_id
                order by start_date, end_date nulls last, subscription_status
            ) as rn
        from typed
    ) as ranked
    where rn = 1
)

select
    subscription_id,
    customer_id,
    plan,
    signed_mrr_eur,
    start_date,
    end_date,
    subscription_status
from deduped
