select *
from {{ ref('fct_cohort_nrr') }}
where abs(nrr - (current_mrr_eur / nullif(starting_mrr_eur, 0))) > 0.000001
