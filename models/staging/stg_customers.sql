with source as (
    select * from {{ ref('src_dim_customers') }}
),

cleaned as (
    select
        trim(customer_id) as customer_id,
        trim(company_name) as company_name,
        case
            when nullif(trim(region), '') is null then 'Unknown'
            when upper(trim(region)) in ('DACH', 'DE', 'GERMANY') then 'DE'
            when upper(trim(region)) = 'CH' then 'CH'
            when upper(trim(region)) = 'AT' then 'AT'
            else 'Other'
        end as region,
        case
            when nullif(trim(segment), '') is null then 'Unknown'
            when lower(trim(segment)) = 'smb' then 'SMB'
            when lower(trim(segment)) = 'mid-market' then 'Mid-Market'
            when lower(trim(segment)) = 'enterprise' then 'Enterprise'
            else 'Other'
        end as segment,
        cast(nullif(trim(cast(signup_date as varchar)), '') as date) as signup_date
    from source
),

-- Deduplicate raw customer rows by customer_id in staging.
-- This preserves original seed files while ensuring the cohort and
-- customer-level metrics are built from a unique set of customers.
deduped as (
    select *
    from (
        select
            *,
            row_number() over (
                partition by customer_id
                order by signup_date nulls last,company_name, region, segment
            ) as row_number
        from cleaned
    )
    where row_number = 1
)

select
    customer_id,
    company_name,
    region,
    segment,
    signup_date
from deduped
