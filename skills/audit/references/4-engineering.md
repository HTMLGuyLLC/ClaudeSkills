# Group 4: Practices, quality, leftovers, cost, delivery

## practices

**Framework first:** use the recommended approach instead of custom code. Check the current docs for the framework version in use. Examples: built-in routing, data fetching, forms, image handling, and auth helpers rather than hand-rolled versions.

**Build vs. buy:** flag a wrong choice in either direction.
- Write it yourself when it's simple and unlikely to change, such as a small helper that would otherwise pull in a package.
- Use a well-tested package when it's easy to get wrong or keeps changing: auth, crypto, dates and timezones, payments, parsing, sanitizing, email deliverability.
- Weigh package health, size, license, and the upkeep cost of each new dependency.

**General:** the right abstraction level, clear separation of concerns, no premature abstraction, and types used rather than bypassed (`any`, `@ts-ignore`, unchecked casts).

## quality

- **Not overly verbose:** say it in fewer lines when that's equally clear. Remove needless wrappers and comments that repeat the code.
- **Not duplicative:** no large repeated chunks. Small repetition is fine; three real uses justify a shared helper. Use scanner output when available.
- **Current:** latest stable language features, APIs, and conventions. Flag deprecated functions and patterns the ecosystem has moved past.
- **Readable:** clear names, small focused functions, matches surrounding style, and no leftover debug code or stale TODOs.
- **Lint and types:** clean for the code in scope.

**Dead and orphaned code**

Start with scanner results when they exist, then confirm each item by searching. Tools miss dynamic uses and report false positives, and they rarely see orphaned product surfaces at all. On a diff, check what the change stopped using, since removing a caller can orphan what it called. On `all`, check the whole repo.

- **Dead code:** unreachable branches, code after a return, conditions that are always true or false, commented-out blocks, and unused functions, classes, exports, variables, parameters, and imports.
- **Orphaned code:** code that still builds but nothing in the product reaches. That means files nothing imports, pages and components no link or menu leads to, endpoints no client calls, jobs nothing schedules, events nothing fires, styles nothing uses, and tables or columns nothing reads.
- **Kept alive only by tests:** code used only by its own tests is orphaned, and so are the tests.
- **Stuck flags:** a feature flag that's permanently on or off leaves one side dead.
- **Chains:** removing one item often orphans what it called, so follow the chain and report it as one finding.

**Severity:** usually Low. Use Medium if it could mislead someone. Use at least Medium for an orphaned endpoint, page, or job that can still be reached, because it's untested and unwatched attack surface. Rate it under `security` too if it exposes data or skips a permission check.

**When fixing:** search strings, config, reflection, and dynamic imports before deleting, and leave anything you can't prove is unused as a finding. Dropping a table or column is a migration, so a person decides.

**Don't flag:** a library's public API, entry points the framework finds by convention, parameters a required signature forces, or generated code.

**File structure and size**

Application flows, such as routes, handlers, jobs, page components, and main functions, should read like a short list of steps. The details live in named classes, functions, and modules that the flow imports and calls.

- **Flows stay high level:** a reader can follow the steps without reading how each one works. Flag a flow that mixes its steps with inline validation, queries, formatting, or provider calls.
- **Real units get their own file:** classes, large functions, and shared interfaces or types live in their own files, placed by the repo's existing layout.
- **Each file has one job:** flag a file that mixes unrelated jobs, or that has grown until a reader can't hold it in their head. Use the repo's limits if it has them. Otherwise, a file over about 400 lines or a function over about 50 is a prompt to look, not a finding by itself.

A finding must name the harm this structure would prevent:
- Reading one step loads unrelated code into an AI's context or a person's head.
- Unrelated work collides in the same lines, causing merge conflicts.
- The flow is slow to scan, or confusing to follow.
- The logic is hard to remove, or to put behind a feature flag.
- The logic can't be reused without copying it.

**Don't flag:** a small helper used once that reads better beside its caller, splitting that makes readers jump between files to follow one idea, a wrapper or abstraction with nothing behind it, layouts the framework requires, or generated code. On a diff, flag only what the change added or made worse, and don't ask for a whole file to be refactored because of a small edit.

## leftovers

`quality` judges how the code is written. This lens asks whether something should exist at all. AI work often goes through several attempts, and pieces of the early ones stay behind. They look deliberate, so the next reader, human or AI, trusts them and builds on them.

**Compare the attempts with production.** Read the commits since the base branch (`git log -p <base>..HEAD` where a base exists), and look for what was added early and later abandoned. The test for each suspect is whether it ever reached production. Check the base branch, release tags, and applied migrations. On `all`, compare against the latest release instead.

**Left over from earlier attempts**
- Code that handles something that never shipped: a compatibility shim, fallback, migration path, or "old format" branch for a name, column, or API that only ever existed on this branch.
- A migration that adds something a later unmerged migration removes. These can be collapsed before merge.
- Comments, docs, tests, or logs that mention an abandoned approach, such as "no longer uses X", "the new version", or "instead of the old Y". Readers may go looking for something that never existed.
- Temporary names that stuck, like `v2`, `new`, `final`, or `temp`, when nothing else exists to compare them with.
- Feature flags, settings, env vars, and packages added for an abandoned approach.
- Tests that only prove code that's now unused, mocks of removed things, and one-off scripts, debug pages, sample data, plans, and scratch files.

**Repetitive or unnecessary**
- Two ways of doing the same job, where the second was added without removing the first.
- Checks repeated at several layers with no extra protection, and fallbacks for cases that can't happen.
- Settings, options, or parameters with only one value ever used.
- For users: the same message, label, or explanation shown repeatedly on one screen, UI that restates what's already obvious, and steps, confirmations, or fields that add nothing.

**Severity:** Medium when it could mislead someone, such as anything that refers to something that never existed. Low when it's only clutter. A finding says what the item is, why it's safe to remove, and how you know it never shipped or isn't used.

**When fixing:** search for every reference before deleting, including strings, config, and dynamic lookups. Leave anything you can't prove is unused as a finding for a person.

**Don't flag:** compatibility for anything that really shipped, including data, clients, or API users still on the old form. Also leave repetition that's deliberate, such as a CTA repeated on a long page, defense in depth at a real trust boundary, or history that's meant to be history, such as a changelog or decision record.

## cost

Use AI only when deterministic algorithms don't suffice. If a deterministic method can handle the first round, AI should be the fallback.

- Could a regex, rule, lookup, parser, full-text search, or SQL query do this job, fully or for the common cases?
- Are cheap checks done first, with AI handling only the uncertain leftovers?
- Is the cheapest adequate model used, with prompt caching, batching, trimmed context, and output limits?
- Are results cached so the same input isn't paid for twice?
- Are there per-user and global spend limits, so one user or a loop can't run up the bill? Does the free plan have a hard cap?
- Is usage measured per feature and per plan, and does each plan's price cover its AI cost?

Also check non-AI spend: costly queries, unbounded storage, egress, email and SMS, per-seat tools, and compute that runs when idle.

**Don't flag:** AI used for work that truly needs it, such as open-ended language understanding or generation.

## delivery

- **Rollout:** risky changes sit behind a flag or staged rollout, and the change can be rolled back, including its data changes.
- **Backward compatibility:** public APIs, webhooks, file formats, and saved data keep working, or there's a versioned migration. Old clients and cached pages still work during a deploy.
- **Config:** new env vars are documented, in the example file, validated at startup, and set for every environment. Defaults are safe.
- **CI/CD and environments:** the build passes, deploy order is safe, and staging matches production where it matters.
- **Versioning:** version and changelog updates follow the project's release process.
