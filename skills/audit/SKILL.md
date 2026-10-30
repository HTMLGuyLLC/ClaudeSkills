---
name: audit
description: Full product and code audit of uncommitted changes, the latest PR, a branch, a path, or the whole repo. Covers security (OWASP, PCI, dependency versions), performance, resilience, error handling, logging, alerting, analytics, accessibility, best practices, tests, simplicity, innovation, AI cost, code quality, legal, docs, consistency, and customer persona reviews. Use whenever the user says audit, "/audit", "check everything", "is this ready to ship", "pre-release review", or asks to review changes across several of these areas, even if they don't say "audit". For a bug hunt alone use /code-review; for a security check alone use /security-review.
argument-hint: "[auto|uncommitted|pr [n]|branch|last [n]|all|<range>|<path>] [lens,lens] [--quick] [--fix]"
---

# Audit

Check a set of changes against every lens in the table below, then report only verified findings, ranked by harm. Deterministic tools run first, and AI judgment covers what they can't.

**Arguments:** $ARGUMENTS

## Rules that keep the audit useful

- **Scope limits what gets judged, not what gets read.** Findings must relate to the changes in scope, but read the whole repo for context. A renamed label is a finding if the old name survives elsewhere. A new helper is a finding if a shared one already exists.
- **Every lens gets a result.** Report each as Pass, Findings, N/A, or Not verified, with a one-line reason. A silent skip reads as a pass, and that is the worst failure this skill can have.
- **Evidence or it isn't a finding.** Each one cites `file:line` or a tool result and describes a concrete way it hurts someone. "Consider improving X" is not a finding.
- **Never claim what wasn't run.** Page load, contrast, and live behavior need a running app. If it wasn't measured, mark it Not verified and say what would verify it.
- **Check facts that change.** Look up versions, CVEs, standards editions, and legal rules with tools or the web, not memory.
- **The project's own rules count.** `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, and `DESIGN.md` set the bar. A breach is a finding, and a documented exception is not.
- **No code changes unless `--fix` is passed.** The only file an audit writes is its report.

## Lenses

| Group | Lens id | Covers | Checklist |
|---|---|---|---|
| 1 | `security` | Permissions, login, sessions (extra attention), credential handling, OWASP, PCI, dependencies on latest versions, abuse | `references/1-security-legal.md` |
| 1 | `legal` | Terms, privacy, disclaimers, regional obligations, licenses | same |
| 2 | `performance` | Page load, query optimization, parallel calls, caching | `references/2-reliability.md` |
| 2 | `resilience` | Retries, backoff, try/catch, timeouts, scaling | same |
| 2 | `errors` | Proactive error handling and user-facing failure | same |
| 2 | `data` | Migrations, integrity, concurrency, idempotency | same |
| 3 | `logging` | Useful, structured, safe logs | `references/3-observability-testing.md` |
| 3 | `alerting` | Failures reach a human | same |
| 3 | `analytics` | Product events and funnels | same |
| 3 | `tests` | Unit, integration, performance tests | same |
| 4 | `practices` | Framework-recommended approach, build vs. buy | `references/4-engineering.md` |
| 4 | `quality` | Concise, not duplicated, current conventions | same |
| 4 | `cost` | Deterministic first, AI as fallback, spend limits | same |
| 4 | `delivery` | Rollout, rollback, compatibility, config, CI | same |
| 5 | `a11y` | WCAG AA minimum, AAA when low-hanging fruit | `references/5-experience.md` |
| 5 | `simplicity` | Plain words, fast setup, progressive depth | same |
| 5 | `consistency` | Verbiage, design, architecture, ideals | same |
| 5 | `docs` | README, markdown, help center, blog, changelog | same |
| 5 | `ux` | UI states, responsive, i18n, SEO | same |
| 6 | `personas` | Walkthroughs as each customer type | `references/6-product.md` |
| 6 | `plans` | Plan gating, billing, upgrade and downgrade paths | same |
| 6 | `innovation` | AI or new technology that makes it feel slick | same |

## Step 1: Resolve the scope

```bash
bash ~/.claude/skills/audit/scripts/scope.sh <scope arguments>
```

Pass only the scope part of the arguments. Lens names and flags stay out. With no scope, `auto` picks the first that exists: uncommitted changes, branch commits ahead of the base, the latest PR, the last commit. For a request in plain words ("the checkout flow", "everything since Tuesday"), translate it into a path or range yourself.

The output gives `mode`, `label`, `diff_cmd`, and the file list. If it prints `also_ahead`, say the audit covers only the uncommitted work and that those commits weren't included.

If the scope is empty, say so and stop.

## Step 2: Load project context

Read what's cheap and tells you the most:

- `.claude/audit.md` if present (optional config, format in `references/project-config.md`)
- `CLAUDE.md`, `AGENTS.md`, the README, and the package manifest
- The pricing or plans page, and any privacy or terms pages

Record the stack, whether it has a UI, who the customers are, what plans exist, whether it handles money or personal data, and whether it calls AI providers.

## Step 3: Run the deterministic tools

Create a temp directory with `mktemp -d`, then pass that literal path as `<audit-dir>`:

```bash
bash ~/.claude/skills/audit/scripts/scanners.sh <audit-dir>
```

Use a 5-minute command timeout. The script runs only tools already installed, downloads nothing, and doesn't run project scripts. Its summary shows what ran, what was skipped, and what to install for better coverage. A non-zero exit on a scanner usually means it found something, not that it failed.

If no scanner reported on dependency versions, compare the direct dependencies with the registry yourself (`npm view <package> version`, or the web for other ecosystems). This applies in `--quick` too. Known vulnerabilities stay Not verified if nothing could check them.

Also run the project's own lint, type check, and the tests covering the scope if the commands are clear from its manifest. If a dev server config exists and the scope touches UI, use it for real page-load and accessibility measurements. A lens that needs one of these and didn't get it is Not verified.

## Step 4: Decide which lenses apply

Select lenses from the arguments if given, otherwise all of them. Mark a lens N/A only for a concrete reason, such as "`a11y`: no UI in this repo" or "PCI: no card handling; payments go through Stripe Checkout." `security`, `consistency`, and `docs` are rarely N/A, because small text changes can still leak a secret, break a term, or make docs stale.

## Step 5: Review

**Standard:** spawn one Agent per group that has applicable lenses, all in the same message, using the Opus model because this is judgment work. Give each agent this brief, filled in:

```
Audit lenses [ids] for [project: stack, customers, plans, what it handles].
Scope: [label]. See the changes with: [diff_cmd]. Files: [list].
Scanner results are in [AUDIT_DIR]; read the summary first.
Read ~/.claude/skills/audit/references/[group file] and apply only your lenses.
Read the whole repo as needed, including outside the scope. Do not edit anything.
Return for each lens: status (Pass, Findings, N/A, Not verified) with a one-line reason.
Return for each finding: lens, severity, confidence (high/medium), file:line,
what's wrong, who it hurts and how, the fix, and effort (S/M/L).
Severity: Critical = exploitable, data loss, or legal exposure now. High = likely to
hurt real users or revenue. Medium = real but limited harm. Low = worth tidying.
Idea = an optional improvement, not a defect.
Skip anything you can't support with evidence. A short honest list beats a long one.
```

**`--quick`:** skip subagents. Review the selected lenses yourself, looking only for Critical and High problems. Step 6 still applies. Report only those findings, in chat and in the file, with no Medium, Low, or Idea counts. A lens with neither gets "Pass (quick)". Say the audit was quick.

**Large scopes (`all`, or over about 100 changed files):** keep the same groups but tell each agent to start with the riskiest areas (auth, payments, data writes, public endpoints) and to list what it didn't reach. Mark partly covered lenses Not verified.

## Step 6: Verify and merge

Reviewers overreport, so don't pass their output through unchecked.

1. Merge duplicates. Keep one finding, noting every lens it touches.
2. Reopen the cited code for each Critical and High finding and try to disprove it. Drop anything that is already handled elsewhere, unreachable, or false.
3. Check the rest more lightly. Demote or drop findings with weak evidence.
4. Trace systemic findings: if a flaw appears once, search for the same pattern elsewhere and list every instance in the one finding.

Keep a count of what you dropped.

## Step 7: Report

Write the full report to `.claude/audits/YYYY-MM-DD-<label>.md` in the project, using `references/report-template.md`. Create the folder if needed. Keep it out of commits without changing tracked files:

```bash
grep -qxF '.claude/audits/' "$(git rev-parse --git-path info/exclude)" || echo '.claude/audits/' >> "$(git rev-parse --git-path info/exclude)"
```

Then show this in chat, verdict first:

- **Verdict:** Don't ship (any Critical), Ship after fixes (any High), or Ship (neither).
- The scope audited, in one line.
- A table of every lens and its status.
- Every Critical and High finding, with `file:line`, the harm, and the fix.
- Counts of Medium, Low, and Idea, with the report's path.
- Not verified items, and what would verify them.
- Scanners worth installing, only if they would have changed coverage.

If there are findings to fix, ask which ones. Only ask about findings whose fix the chat has already shown, and show the fix first for any Medium or Low you want to include.

## Step 8: Fix (only with `--fix` or after approval)

Fix Critical and High first. Apply each fix to every instance found, add tests for changed behavior, and run the tests covering those changes. Leave Ideas alone unless asked. Don't commit unless asked.
