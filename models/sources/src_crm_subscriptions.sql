-- Wrap seed `crm_subscriptions` as a dbt model for easier referencing in staging
select * from {{ ref('crm_subscriptions') }}
