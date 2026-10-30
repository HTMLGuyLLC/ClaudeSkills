# Audit report template

```markdown
# Audit: <project> — <scope label>

**Date:** YYYY-MM-DD
**Verdict:** Don't ship | Ship after fixes | Ship
**Depth:** standard | quick | full repo
**Findings:** X Critical, X High, X Medium, X Low, X Ideas (X dropped in verification)

## Lens coverage

| Lens | Status | Note |
|---|---|---|
(one row for every lens: Pass, Findings (count), N/A, or Not verified, with a one-line reason)

## Critical

### C1. <Short title>
- **Lens:** security
- **Where:** `path/file.ts:42` (and every other instance)
- **Problem:** What's wrong, with evidence.
- **Harm:** Who it hurts and how.
- **Fix:** The specific change.
- **Effort:** S | M | L
- **Confidence:** high | medium

## High
## Medium
## Low
(same format; Low may be one line each)

## Persona walkthroughs

### <Persona>
- **Goal:**
- **Path:**
- **Worked:**
- **Stuck on:** (link finding ids)

## Ideas
- **<Idea>:** benefit, effort, running cost.

## Not verified
- <What wasn't checked>, and what would verify it.

## Tools
| Tool | Result |
|---|---|
(what ran, what was skipped, and what to install)
```

Omit empty severity sections, but always keep Lens coverage and Not verified.
