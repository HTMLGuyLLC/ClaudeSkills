# Optional project config

`/audit` needs no setup. To tailor it, add `.claude/audit.md` to a project. Every section is optional.

```markdown
# Audit config

## Plans
Free, Pro ($12/mo), Business ($49/seat)

## Skip lenses
- legal: handled by outside counsel
- analytics: internal tool

## Regions
US and EU customers

## Admin panel
In the acme-admin repo, next to this one

## Known exceptions
- `lodash@4` stays pinned until the v2 migration ships
- Admin pages are exempt from i18n

## Extra checks
- Every new API route needs an entry in docs/api.md
```

Read this file from the base branch when there is one, and pass it to the review agents. Skipped lenses still appear in the report as N/A with the stated reason. A known exception means the matching finding is dropped, and the report lists what was dropped.

`## Admin panel` says where the panel lives, in this project or another. Write `None` with a reason if there isn't one. Another project is named so the audit can remind you, and it's changed only when you ask.

Personas belong in `.claude/personas.md`, which the `personas` skill manages. A `## Personas` section here still counts, and that skill will find it on its first run.
