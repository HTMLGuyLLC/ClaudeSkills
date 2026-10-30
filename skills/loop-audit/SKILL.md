---
name: loop-audit
description: Repeatedly runs /audit, fixes what it finds, and audits again until only rare, low-priority edge cases remain. Use whenever the user says loop audit, "/loop-audit", "keep auditing until it's clean", "audit and fix everything", "fix until nothing's left", or wants changes hardened before shipping without reviewing each round. For a one-time report use /audit instead. To repeat something on a timer use /loop.
argument-hint: "[audit scope] [lens,lens] [--max n]"
---

# Loop audit

Audit, fix, and repeat until a full audit finds nothing worth fixing. Everything about how to audit comes from the `audit` skill, so this skill only adds the loop, the stop rules, and the record that survives between rounds.

**Arguments:** $ARGUMENTS

Read `~/.claude/skills/audit/SKILL.md` first. Each round follows its Steps 2 to 6 at standard depth. `--quick` isn't accepted here, because it can't see Medium findings and so can't prove the stop condition.

## Rules

- **Stay honest about "clean".** A parked Critical, a Not verified lens, or a hit round cap all mean the work isn't clean, and the final message must say so first.
- **People decide what code can't.** Park those items (see Sort) and keep fixing everything else.
- **Fix the problem, not the neighborhood.** Make the smallest change that resolves each finding, plus the same flaw elsewhere. Loops that refactor create new findings forever.
- **Don't commit, push, or deploy** unless the user asked.
- **Leave other work alone.** Other sessions may share this checkout. Don't stage, stash, reset, or revert, and don't touch files a fix doesn't need. If a file changed in a way you didn't expect, stop and report it.

## Start

1. Resolve the scope once with the audit skill's `scope.sh`, and keep that result for the whole loop. Never re-resolve it: after the first fix, `auto` would pick something else.
2. If the scope is an open PR, its branch must be checked out, or the fixes land on the wrong code. If it isn't, stop and tell the user.
3. Record a restore point with `git stash create`. This changes nothing and prints a commit hash for tracked changes; if it prints nothing, the restore point is `HEAD`. Untracked files aren't covered.
4. Create the ledger at `.claude/audits/loop-YYYY-MM-DD-<label>.md`, and add `.claude/audits/` to the git exclude as the audit skill describes. If an unfinished ledger for this scope already exists, continue from it and say so.

## The ledger

The ledger is the loop's memory. Update it after every round, so the work survives context compaction or an interruption.

```markdown
# Loop audit: <project> — <scope label>
Status: running | clean | stopped: <reason>
Restore point: <hash>
Scope: <mode>, <diff_cmd>, <files>
Max rounds: <n>

## Rounds
| Round | Type | Critical | High | Medium | Fixed | Parked | Tests |

## Open
## Fixed
- [round] <lens> `file:line`: what was fixed
## Needs you
- <severity> `file:line`: what's needed and why it needs a person
## Rare edge cases (left alone)
- `file:line`: the condition that triggers it, and why it's rare
## Dismissed
- `file:line`: why it isn't a problem
```

Identify a finding by its lens, file, and problem rather than its line number, since lines move.

## Each round

### 1. Audit

Round 1 is full: every applicable lens. Later rounds are partial: only groups with open findings, plus groups whose lenses relate to the files changed in the last round.

Use fresh agents every round, so they aren't anchored to earlier opinions. Add this to each brief:

```
This is round N of a fix loop. Also review the current fixes with: git diff HEAD
Fixes can introduce new problems, so check them as closely as the original change.
Don't re-raise anything below unless the code it depends on has changed:
[Dismissed and Rare edge cases from the ledger]
```

Run the project's lint and tests each round. Run `scanners.sh` in Round 1 and again if dependencies changed. Reuse earlier lens results for groups you skip. Use the audit skill's Step 6 to verify every round.

### 2. Sort

Put every finding in one bucket:

- **Fix:** every Critical, High, and Medium, unless it belongs in Needs you. Also any Low that's cheap to fix (effort S) and isn't a rare edge case.
- **Needs you:** a person has to act or decide. This covers rotating leaked secrets or anything outside the repo, wording of legal text, pricing or plan changes, product or design choices with no clear answer, major dependency upgrades with breaking changes, and migrations that destroy or rewrite data.
- **Rare edge case:** Low severity, and it needs unusual conditions or barely matters when it happens. Write down the condition. If you can't name one, it isn't rare.
- **Dismissed:** verification showed it's wrong or already handled.
- **Idea:** record it in the final report and don't build it.

A finding that comes back after being fixed gets one more attempt using a different approach. If it returns again, move it to Needs you.

### 3. Check the stop rules

Stop at the first one that applies:

| Outcome | When |
|---|---|
| **Clean** | A full round found nothing in Fix. If a partial round finds nothing, run one full round first, because fixes can break lenses the partial round skipped. |
| **Round cap** | This was round `--max` (default 5). |
| **Stalled** | The Fix count hasn't fallen for two rounds in a row. |
| **Blocked** | Tests or the build stayed broken after two repair attempts, or an unexpected file change appeared. |

### 4. Fix

Follow the audit skill's Step 8, working from highest severity down. Add tests for changed behavior. Then run the tests covering those changes and repair anything that broke before starting the next round. Log each fix in the ledger with the files it changed.

Give the user one line per round: `Round 2: 1 High, 4 Medium, 5 fixed, 1 parked, tests pass.` Keep going without asking for approval.

## Finish

Write the final audit report with the audit skill's Step 7, using the last round's results, and mark the ledger's status. Then show in chat:

- **Outcome first:** Clean, Round cap, Stalled, or Blocked, in one line. If anything Critical or High is parked, say "Not ready to ship" and why.
- **Needs you:** every item, with what to do. This is the main thing the user must read.
- **Round table:** the counts for each round.
- **What changed:** the fixes grouped by lens, and whether tests pass.
- **Rare edge cases left alone:** each with its trigger, so the user can disagree.
- **Not verified:** what wasn't checked, and what would verify it.
- **Ideas:** a short list.
- **Files:** the ledger, the report, and the restore point.

State that nothing was committed, unless the user asked for a commit.
