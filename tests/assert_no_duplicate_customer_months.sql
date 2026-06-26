select
    customer_id,
    invoice_month,
    count(*) as row_count
from {{ ref('int_customer_monthly_revenue') }}
group by customer_id, invoice_month
having count(*) > 1
