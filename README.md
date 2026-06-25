# Data Analyst Case Study @ Nelly

Welcome, and thanks for taking the time. This case mirrors the kind of work you'd
own as our first Commercial Data Analyst: pulling data from several imperfect
source systems, modeling it cleanly, and turning it into a metric the whole
company can trust.

We care far more about **how you think and the quality of your modeling** than
about how much you finish.

> **Time budget:** ~3–4 hours. Quality over completeness. If you run out of time,
> document what you'd do next instead of rushing it.

---

## Quick start

This project runs **fully locally** using dbt + DuckDB — no warehouse, no
credentials.

```bash
# 1. (recommended) create a virtual environment
python3 -m venv .venv && source .venv/bin/activate

# 2. install dependencies
pip install -r requirements.txt

# 3. tell dbt where the profile lives (it's in this repo)
export DBT_PROFILES_DIR=$(pwd)

# 4. load the data, build, and test
dbt seed
dbt run
dbt test
```

If all four commands succeed, you're set up correctly. The project ships with one
trivial placeholder model so this runs green before you write anything — delete or
replace it as you like.

> On Windows / PowerShell, replace step 3 with: `$env:DBT_PROFILES_DIR = (Get-Location).Path`

Prefer Postgres, BigQuery, SQLMesh, etc.? Go ahead — just update `profiles.yml`
and note any setup steps in your PR.

---

## The task

Build a model that produces **cohort-based Net Revenue Retention (NRR)** from the
three seed sources, and open it as a **pull request**.

NRR should let us answer: *for customers who joined in a given period (cohort),
how does their recurring revenue evolve over the following months* — including
expansion, contraction, and churn, but excluding net-new customers.

You define the exact grain and cohort logic — just make your choices explicit.

### The data (in `seeds/`)

| File | Source system | What it represents |
|------|---------------|--------------------|
| `crm_subscriptions.csv` | CRM (Salesforce-like) | Contracts with **signed** MRR, plan, start/end, status |
| `billing_invoices.csv` | Billing/Invoicing | Monthly **actual** invoiced amounts per subscription |
| `dim_customers.csv` | CRM | Customer attributes: region, segment, signup date |

A few things you'll likely run into (this is intentional — it's the job):
- More than one contract per customer, including a mid-contract plan change.
- `signed_mrr_eur` (CRM) and `actual_amount_eur` (billing) **do not always match**.
  Decide which is the source of truth for NRR, and why.
- Some records are ambiguous (status vs. end date vs. presence of invoices).
- The usual: duplicates, blanks/NULLs, inconsistent formatting, a few gaps.

We won't tell you how to resolve these. How you spot and handle them is exactly
what we want to see.

---

## Deliverables

1. **A dbt project** structured into layers (e.g. staging → intermediate → mart),
   with a final model exposing cohort-based NRR.
2. **Meaningful dbt tests** (e.g. `not_null`, `unique`, `relationships`).
3. **A short `DECISIONS.md`** — a template is included; fill it in.
4. **A pull request** with your work on a branch, with a description written as if
   a teammate will review it.

Please **don't** build a dashboard or do visualization polish — we want the model,
not the chart.

---

## A note on AI tools

Using AI assistants (Claude, Copilot, etc.) is **explicitly allowed**. We use them
too. We'll do a **live walkthrough** of your PR together, going deep on *why*
you made specific modeling decisions, and we'll ask you to make a small change
live. Make sure the work is genuinely yours to defend.

---

## How we'll evaluate (roughly in order of weight)

1. **Data modeling** — layering, grain, where business logic lives, sensible
   normalization/denormalization trade-offs.
2. **Correctness & handling of messy data** — did you notice the traps and resolve
   them deliberately (and document it)?
3. **Testing & reliability** — meaningful tests, not box-ticking.
4. **Reasoning & communication** — `DECISIONS.md` and the PR description.
5. **dbt craft** — structure, naming, materializations, refs/sources.

We're explicitly **not** scoring visualization, feature count, or whether you
covered every edge case. A smaller, well-reasoned submission beats a large messy
one.

Good luck. We're looking forward to digging into it with you.
