# Agent Instructions

This repository is a dbt case study for cohort-based Net Revenue Retention.

Before changing models, tests, or metric logic, read:

- `docs/agent_rules.md`
- `docs/agent_build_plan.md`
- `docs/interview_and_stakeholder_brief.md`
- `DECISIONS.md`

When a change affects metric definitions, model grain, date semantics, source-of-truth assumptions, or testing strategy, update the relevant documentation in the same change.

Use this order of operations:

1. Identify which layer owns the change: staging, intermediate, or mart.
2. Make the smallest model change that satisfies the request.
3. Update YAML descriptions or tests if model columns, grain, or assumptions changed.
4. Update docs if metric logic or business interpretation changed.
5. Run validation before pushing:

```bash
export DBT_PROFILES_DIR=$(pwd)
dbt seed --full-refresh
dbt build
dbt show --select fct_cohort_nrr --limit 20
```

Keep `DECISIONS.md` short. Use `docs/interview_and_stakeholder_brief.md` for fuller explanation and presentation notes.
