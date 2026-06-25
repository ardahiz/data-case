select *
from {{ ref('int_customer_cohorts') }}
where starting_mrr_eur <= 0
