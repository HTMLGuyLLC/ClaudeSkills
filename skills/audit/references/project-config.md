# Optional project config

`/audit` needs no setup. To tailor it, add `.claude/audit.md` to a project. Every section is optional.

```markdown
# Audit config

## Personas
- Solo freelancer on the free plan, tracks one client
- Agency owner with 20 seats, needs client-level reports

## Plans
Free, Pro ($12/mo), Business ($49/seat)

## Skip lenses
- legal: handled by outside counsel
- analytics: internal tool

## Regions
US and EU customers

## Known exceptions
- `lodash@4` stays pinned until the v2 migration ships
- Admin pages are exempt from i18n

## Extra checks
- Every new API route needs an entry in docs/api.md
```

Read this file from the base branch when there is one, and pass it to the review agents. Skipped lenses still appear in the report as N/A with the stated reason. A known exception means the matching finding is dropped, and the report lists what was dropped.
