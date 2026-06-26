-- Wrap seed `billing_invoices` as a dbt model for easier referencing in staging
select * from {{ ref('billing_invoices') }}
