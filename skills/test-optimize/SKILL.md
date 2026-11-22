---
name: test-optimize
description: Makes a project's unit tests run faster without losing any protection. Measures where the time goes, then fixes runner config, slow tests, and duplicated or scattered tests, one change at a time. Every change must keep every test case, keep them passing, and keep per-file coverage, or it gets reverted.
argument-hint: "[path or package] [--plan]"
disable-model-invocation: true
---

# Optimize unit tests

Make the unit tests below run faster while catching exactly the bugs they caught before.

**Target:** $ARGUMENTS

With no target, use the whole repo's unit tests. In a monorepo, measure each package and start with the slowest. `--plan` stops after Step 3 with the list of changes and their expected savings, and changes nothing.

## Rules

- **Protection is the hard limit. Speed is the goal inside it.** After every change, all three hold, or the change is reverted:
  1. Every test case from the baseline still runs, under the same name or one mapped to it.
  2. Every test that passed still passes.
  3. No file's covered lines, branches, functions, or statements go down.
- **Never weaken a test to speed it up.** No skipping, deleting assertions, loosening matchers, lowering timeouts until something stops failing, or mocking out the code the test exists to check. A mocked dependency must be one the test doesn't exercise.
- **Remove a test only when another test checks the same behavior with the same inputs.** Write each removal into `allow.txt` as `<test id> => <the test that covers it now>`. Show the user every line of it before committing.
- **Change one kind of thing at a time** and measure it alone. Keep it only if it saves more time than the run-to-run noise.
- **Treat failures already in the baseline as the baseline.** Don't fix or hide them here. List them in the report.
- **Work on a branch in a separate worktree**, since other sessions may share the checkout. Commit each kept change on its own.
- **Run tests in the background.** Suites can take minutes.
- **Use the cheapest capable model for helpers.** Opus plans and judges. Sonnet applies a clear, file-by-file plan. Haiku does mechanical edits like import path changes.

## The working folder

Put reports in the session scratchpad, or in `.test-optimize/` at the repo root added to `$(git rev-parse --git-path info/exclude)`. Never commit it.

```
baseline-1.json, baseline-2.json   Two baseline runs (report format of the runner)
baseline.log                       Console output, with the runner's own time split
coverage-before/                   Coverage summary at baseline
allow.txt                          Tests replaced on purpose, and what covers each now
ledger.md                          Every change tried: time before and after, kept or reverted, why
```

`${CLAUDE_SKILL_DIR}/scripts/report.mjs` reads Jest-format JSON (Jest, Vitest) and JUnit XML (pytest, Go via gotestsum, PHPUnit, and most others):

```bash
node ${CLAUDE_SKILL_DIR}/scripts/report.mjs summary  <report>                    # where time goes
node ${CLAUDE_SKILL_DIR}/scripts/report.mjs diff     <before> <after> [--allow allow.txt]  # tests kept?
node ${CLAUDE_SKILL_DIR}/scripts/report.mjs coverage <before-summary> <after-summary>       # coverage kept?
```

`diff` and `coverage` print `protection: kept` or `protection: LOST` and exit 1 on a loss. A test that moved to another file under the same name counts as kept.

## Step 1: Find the tests

Find the runner, its config, the unit test command, and where the test files live. Read `${CLAUDE_SKILL_DIR}/references/runners.md` for the runner you find. Leave end-to-end, browser, and integration suites alone unless the target names them.

Note the machine's core count and whether a CI config runs the same command. A change that helps on a laptop can hurt on a 2-core CI runner.

## Step 2: Measure the baseline

Run the full unit suite twice with a machine-readable reporter, then once with coverage. Record wall time for each. The gap between the two plain runs is the noise. A change has to beat it to count.

Run `report.mjs summary` on the first report. Also read the runner's own time split (Vitest prints transform, setup, collect, tests, and environment), which shows whether time goes to running tests or to loading files.

## Step 3: Find where the time goes

Work through these in order. The early ones usually pay most and touch the fewest files.

1. **Per-file overhead.** When load, setup, and environment time dwarfs test time, look at config before any test: test environment applied to files that don't need it, heavy setup files, slow transforms, isolation settings, pool, worker count. One config change can cut every file at once.
2. **Slow files and tests.** The top of `slowest_files` and `slowest_tests`. Look for real waits (`sleep`, `setTimeout`, polling, retries), real network or disk, expensive setup repeated per test that could be built once without sharing mutable state, and imports of large modules the test doesn't use.
3. **Duplicated tests.** Grep for the same function called with the same inputs in several tests or files. `same_title_in_several_files` gives leads. Merge exact duplicates. Turn near-identical tests into one table-driven test (`it.each`, `pytest.mark.parametrize`, Go table tests) that keeps one named case per original, so the names still match in `diff`.
4. **Scattered files.** Many tiny files for one module, each paying its own per-file overhead. Merge them into one file per module when the per-file cost is large. Keep the original `describe` names so test ids stay readable.

For each candidate, write down the expected saving (seconds), the files it touches, and the risk. Present this as a table, biggest saving first.

With `--plan`, stop here and show the table.

## Step 4: Change, measure, keep or revert

For each candidate, biggest saving first:

1. Make the change. For a change spanning many files, split it into batches and hand each batch to a helper with exact instructions, then review its diff.
2. Run the affected test files first. Fix or revert before going wider.
3. Run the full suite with the reporter. Then run `report.mjs diff baseline-1.json <new> --allow allow.txt`.
4. For any change that touches test code or mocks, also run coverage and `report.mjs coverage`. Config-only changes (pool, workers, environment) still need one coverage check before the final commit.
5. For isolation or shared-setup changes, run the affected files three times in shuffled order. Any flake means revert.
6. Keep it only if protection is kept and the time saved beats the noise. Otherwise revert it. Either way, add a ledger line.
7. Commit kept changes one at a time, with the measured saving in the message.

Stop when the remaining candidates are each worth less than the noise, or are risky changes that need the user's call.

## Step 5: Final check and report

Run the full suite twice and coverage once on the final state. Run `diff` and `coverage` against the baseline one last time.

Report to the user:

- **Time:** wall time before and after (mean of two runs), and the runner's own time split before and after.
- **Protection:** test count before and after, `protection: kept` from both checks, and every `allow.txt` line in full.
- **Kept changes:** one line each, with the seconds it saved.
- **Reverted:** one line each, with why.
- **Not done, needs a decision:** risky options with their expected saving and risk, such as turning off isolation broadly or sharding in CI.
- **Already failing:** tests that failed at baseline.

Then ask before merging or pushing, following the project's own rules for both.
