with source as (
    select * from {{ ref('dim_customers') }}
),

cleaned as (
    select
        trim(customer_id) as customer_id,
        trim(company_name) as company_name,
        case
            when nullif(trim(region), '') is null then 'Unknown'
            when upper(trim(region)) in ('DACH', 'DE', 'GERMANY') then 'DACH'
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
        cast(nullif(trim(signup_date), '') as date) as signup_date
    from source
)

select * from cleaned
