-- Intermediate: Customer cohorts with starting MRR
-- Unique Key: customer_id
-- Purpose: Identify customer cohort (first month with positive revenue) and starting MRR for NRR calculation
-- Note: Only includes customers with at least one month of positive revenue
with customer_monthly_revenue as (
    select * from {{ ref('int_customer_monthly_revenue') }}
),

first_positive_revenue_month as (
    select
        customer_id,
        min(invoice_month) as cohort_month
    from customer_monthly_revenue
    where actual_mrr_eur > 0
    group by customer_id
)

select
    cmr.customer_id,
    cmr.company_name,
    cmr.region,
    cmr.segment,
    cmr.signup_date,
    fprm.cohort_month,
    cmr.actual_mrr_eur as starting_mrr_eur
from first_positive_revenue_month as fprm
inner join customer_monthly_revenue as cmr
    on fprm.customer_id = cmr.customer_id
    and fprm.cohort_month = cmr.invoice_month
