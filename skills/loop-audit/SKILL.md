---
name: loop-audit
description: Repeatedly runs /audit, fixes what it finds, and audits again until only rare, low-priority edge cases remain. Only runs when typed as /loop-audit.
argument-hint: "[audit scope] [lens or bundle,...] [--max n]"
disable-model-invocation: true
---

# Loop audit

Audit, fix, and repeat until a full audit finds nothing worth fixing. Everything about how to audit comes from the `audit` skill, so this skill only adds the loop, the stop rules, and the record that survives between rounds.

**Arguments:** $ARGUMENTS

Read `${CLAUDE_SKILL_DIR}/../audit/SKILL.md` first, and again at the start of each round, because it may not survive context compaction. In that file, `${CLAUDE_SKILL_DIR}` means the `audit` folder. Each round follows its Steps 2 to 6 at standard depth. `--quick` isn't accepted here, because it can't see Medium findings and so can't prove the stop condition.

## Rules

- **Stay honest about "clean".** Use the outcome names under "Check the stop rules" exactly. A parked Critical or High, a Not verified lens, unread code, or a hit round cap all mean the work isn't clean, and the final message must say so first.
- **People decide what code can't.** Park those items (see Sort) and keep fixing everything else.
- **Fix the problem, not the neighborhood.** Make the smallest change that resolves each finding, plus the same flaw elsewhere. Loops that refactor create new findings forever.
- **Don't commit, push, or deploy** unless the user asked.
- **Leave other work alone.** Other sessions may share this checkout. Don't stage, stash, reset, or revert, and don't touch files a fix doesn't need. If a file changed in a way you didn't expect, stop and report it.

## Start

1. Look for an unfinished ledger first: any `.claude/audits/loop-*.md` with `Status: running`. If one matches this request, continue from it, reuse its scope, lenses, and restore point, and skip the rest of Start. Say so.
2. Resolve the scope once with the audit skill's `scope.sh`, and keep that result for the whole loop. Never re-resolve it: after the first fix, `auto` would pick something else. Handle a failure, an empty scope, and `also_ahead` as audit Step 1 describes.
3. If the scope is an open PR, its branch must be checked out, or the fixes land on the wrong code. If it isn't, stop and tell the user.
4. If the code isn't the user's, such as someone else's PR, confirm before running its lint, tests, or binaries each round.
5. Create the ledger at `.claude/audits/loop-YYYY-MM-DD-<label>.md`, and add `.claude/audits/` to the git exclude as the audit skill describes. Do this while the user is present, because `.claude/` and `.git/` are protected paths that may prompt for approval. If they prompt, tell the user that an unattended run needs them approved for this session.
6. Record a restore point with `git stash create`. This changes nothing and prints a commit hash for tracked changes; if it prints nothing, use the hash from `git rev-parse HEAD`. That doesn't cover untracked files, so copy any in the scope to `.claude/audits/loop-YYYY-MM-DD-<label>-restore/`, keeping their paths.
7. State the worst-case cost before Round 1: agents per round from the audit skill's sizing table, times max rounds, times about 120k tokens. At full size that's about 3.6M tokens.

## The ledger

The ledger is the loop's memory. Update it after every round, so the work survives context compaction or an interruption.

```markdown
# Loop audit: <project> — <scope label>
Status: running | clean | stopped: <reason>
Restore point: <hash>
Scope: <mode>, <diff_cmd>, <files>
Lenses: <all, or the selected ids>
Max rounds: <n>
Commit allowed: <yes or no>

## Rounds
| Round | New Critical | New High | New Medium | Fixed | Newly parked | Tests |

## Open
## Not reached
- Areas the agents listed as unread
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

Run every selected lens that applies each round, because a fix in one area can break another. Use the audit skill's sizing table. Agents start with the `Not reached` list, so each round covers new ground. Use fresh agents every round, so they aren't anchored to earlier opinions. Add this to each brief:

```
This is round N of a fix loop. Also review the current fixes with: git diff HEAD
and the new files listed by: git ls-files --others --exclude-standard
Fixes can introduce new problems, so check them as closely as the original change.
Don't re-raise anything below unless the code it depends on has changed:
[Dismissed and Rare edge cases from the ledger]
```

Run the project's lint and tests each round. If the changed code can't be run, say so in the ledger and mark `tests` Not verified rather than reporting a pass. Run `scanners.sh` in Round 1 and again if dependencies changed, which overrides audit Step 3. Use the audit skill's Step 6 to verify every round.

### 2. Sort

Put every finding in one bucket:

- **Fix:** every Critical, High, and Medium, unless it belongs in Needs you. Also any Low that's cheap to fix (effort S) and isn't a rare edge case.
- **Needs you:** a person has to act or decide. This covers rotating leaked secrets or anything outside the repo, wording of legal text, pricing or plan changes, product or design choices with no clear answer, major dependency upgrades with breaking changes, migrations that destroy or rewrite data, and new designs for auth, sessions, payments, or schema when the repo has no pattern to follow. Don't invent a security design to clear a finding.
- **Rare edge case:** Low severity, and it needs unusual conditions or barely matters when it happens. Write down the condition. If you can't name one, it isn't rare.
- **Left open:** a Low that isn't rare and isn't cheap to fix. Keep it in Open, and list it in the final report.
- **Dismissed:** verification showed it's wrong or already handled.
- **Idea:** record it in the final report and don't build it.

A finding that comes back after being fixed gets one more attempt using a different approach. If it returns again, move it to Needs you.

### 3. Check the stop rules

Stop at the first one that applies:

| Outcome | When |
|---|---|
| **Clean** | This round found nothing in Fix, nothing Critical or High is in Needs you, and no lens is Not verified or code unread. |
| **Clean with caveats** | This round found nothing in Fix, but something above stays open. Name it in the outcome line. |
| **Round cap** | This was round `--max` (default 5, minimum 2). Apply any effort S fixes first and list them as not re-audited. Everything else stays Open. |
| **Stalled** | The Fix count was at least as high as the previous round's, two rounds in a row. |
| **Blocked** | Tests or the build stayed broken after two repair attempts, an unexpected file change appeared, or a usage limit ended the run. The ledger stays saved, so a later run can continue. |

### 4. Fix

Follow the audit skill's Step 8, working from highest severity down. A fix may touch files outside the scope when it has to. Add tests for changed behavior. Then run the tests covering those changes and repair anything that broke before starting the next round. Log each fix in the ledger with the files it changed.

Give the user one line per round: `Round 2: 1 High, 4 Medium, 5 fixed, 1 parked, tests pass.` Keep going without asking for approval.

## Finish

Write the report file from the audit skill's Step 7 using the last round's results, then mark the ledger's status. Use the chat format below instead of Step 7's, and don't ask which findings to fix. Show in chat:

- **Outcome first:** Clean, Clean with caveats, Round cap, Stalled, or Blocked, in one line. If anything Critical or High is parked, say "Not ready to ship" and why.
- **Needs you:** every item, with what to do. This is the main thing the user must read.
- **Round table:** the counts for each round.
- **What changed:** the fixes grouped by lens, and whether tests pass.
- **Rare edge cases left alone:** each with its trigger, so the user can disagree.
- **Not verified:** what wasn't checked, and what would verify it.
- **Ideas:** a short list.
- **Files:** the ledger, the report, the restore point, and any restore folder, with how to restore: `git diff <restore point>` shows everything changed since the start.

State that nothing was committed, unless the user asked for a commit.
