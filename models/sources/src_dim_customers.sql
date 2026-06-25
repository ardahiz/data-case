-- Wrap seed `dim_customers` as a dbt model for easier referencing in staging
select * from {{ ref('dim_customers') }}
