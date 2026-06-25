select
    subscription_id,
    invoice_month,
    count(*) as row_count
from {{ ref('int_subscription_monthly_revenue') }}
group by subscription_id, invoice_month
having count(*) > 1
