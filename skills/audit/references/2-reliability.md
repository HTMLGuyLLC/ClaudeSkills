# Group 2: Correctness, performance, resilience, errors, data, migrations, operations

## correctness

Well-built code can still do the wrong thing. This lens asks whether the change does what it was meant to, and gets the right answer. Every other lens assumes this part works.

**Work out what was asked.** Use the user's request, the PR description, linked issues, commit messages, plans, and existing docs or tests. If the goal can't be found, review the logic anyway and mark the requirement checks Not verified.

**Does what was asked**
- Every part of the request is done. No stubs, placeholder values, hardcoded test data, or half-built paths are left.
- Each path connects end to end: the button calls the route, the route saves the field, and the value comes back after a reload.
- Behavior that should stay the same still does, including for existing data.

**Gets the right answer**
- **Business rules:** the logic matches the product's docs, pricing, and policies.
- **Math:** rounding, money stored in the smallest unit, percentages, tax, proration, and division by zero.
- **Boundaries:** empty, one, the limit, one past the limit, and the first and last items.
- **Dates and times:** time zones, daylight saving, month ends, and leap years.
- **Logic:** inverted conditions, wrong operators, mixed-up IDs or units, wrong defaults, and states that can be skipped or reached by mistake.
- **Same number everywhere:** a total on screen matches the email, invoice, report, and export.

**How to check:** take a realistic example and work out the right answer yourself, without using the code. Then follow the example through the code, or run it if you can, and compare.

**Severity:** Critical or High when it gets money, access, or customer data wrong. Medium for a missing part of the request, or a wrong result with limited reach.

**Don't flag:** a different approach you'd have chosen when this one works. How the code is written is covered by `quality`.

## performance

**Lighthouse and Core Web Vitals**

Run Lighthouse on the key pages, on mobile and desktop, and report the real numbers with the page and device. Use a production build, because dev server numbers mislead. Take the median of at least 3 runs. If it can't run, use the browser's tools, or mark the numbers Not verified and review the code only.

| Metric | What it measures | Target |
|---|---|---|
| LCP | When the main content appears | Under 2.5s |
| INP | How fast the page responds to input | Under 200ms |
| CLS | How much the layout jumps | Under 0.1 |
| TTFB | When the server starts responding | Under 0.8s |
| FCP | When anything first appears | Under 1.8s |
| TBT | How long the page is blocked from responding | Under 200ms |
| Lighthouse scores | Performance, Accessibility, Best Practices, SEO | 90 or higher |

- Confirm these thresholds are current, since they change over time.
- INP needs real interaction, so a Lighthouse run uses TBT as a stand-in. Prefer real-user data, such as Chrome UX Report or the project's own monitoring, when it exists.
- Trace each missed target to its cause, rather than only reporting the score.
- Where performance matters, budgets run in CI, such as with Lighthouse CI.

**Page load**
- Server response: slow queries, cold starts, redirect chains, and missing CDN or edge caching.
- Bundle size, code splitting, unused or heavy dependencies, render-blocking scripts, third-party tags.
- Images and fonts: modern formats, sizes, lazy loading, `font-display`.
- Server rendering, static generation, and caching used where the framework supports them.

**Perceived speed**

When a wait can't be removed, it should still feel short. Walk each wait a user can see and ask which of these ideas would shorten it. The examples show the idea and aren't a fixed list, so apply it to whatever this product does, and flag a noticeable wait where one clearly fits and isn't used.
- **Answer before the work finishes:** the UI shows the expected result right away and the real work catches up behind it, as with a like, a save, or a reorder. A failure rolls back and tells the user. Anything hard to undo, such as a payment, send, or delete, shows a pending state instead.
- **Show the shape first:** the user sees something solid straight away, with the real content filling in, such as a skeleton of the layout rather than a blank page or a lone spinner. It matches the final shape so nothing jumps, and very short waits show nothing so it doesn't flash.
- **Show a cheap version first:** a small stand-in appears while the full thing loads, such as a blurred 1 KB image preview, a cached copy, a low-resolution chart, or the first rows of a report.
- **Shape the wait:** the ending decides how long a wait feels, so progress should start slow and finish fast, never stall near the end, and reach 100% only when the work is done.
- **Work while the user is busy with something else:** any time they're reading, typing, or deciding, do the work they'll need next, so the final step feels instant. Upload the file while they write the caption, parse or look up the first field while they type the second, prepare the next step while they read this one, or prefetch the likely next page. Throw away work that the user's changes make stale, cancel and delete what they abandon, and don't spend AI or other paid costs on steps they may never reach.
- **Show the work:** a long wait tells the user what's happening, such as live counts, the current step, or partial results as they arrive, rather than a static "Loading".

These ideas change how a wait feels, never what's true. Each of these is a finding:
- A success shown for something that failed, with no rollback.
- A made-up count, or a progress bar on a timer with no link to the real work.
- A loading state screen readers can't detect, or motion that ignores `prefers-reduced-motion`.

**How to check:** throttle the network and CPU in the running app, then try the main actions and watch what appears and when. Force a failed request to test rollback. Timing and feel can't be proven from code, so mark them Not verified without a running app.

**Query optimization**
- N+1 queries, `SELECT *`, missing indexes on filter, join, and sort columns, unbounded results with no pagination, work done in app code that the database should do.
- Slow paths inside hot loops, and long transactions holding locks.

**Parallel calls**
- Independent awaits run one after another that could use `Promise.all` or the local equivalent.
- The reverse too: unbounded fan-out that needs a concurrency limit.
- Duplicate fetches for the same data on one page or request.

**Other**
- Caching: right layer, invalidation, stampede protection, and no user data in shared caches.
- Work on the request path that belongs in a background job.
- Memory leaks, large payloads, missing compression, needless re-renders, unvirtualized long lists.

**Don't flag:** micro-optimizations on cold paths, speculative caching that adds more risk than it saves, or perceived-speed tricks for waits users don't notice or a product with no UI.

## resilience

- **Timeouts** on every network, database, and AI call.
- **Retries** with exponential backoff and jitter, limited attempts, and only on transient failures. Retrying a non-idempotent write without an idempotency key is a bug.
- **try/catch** at real boundaries: external calls, parsing, background jobs, and top-level handlers. Unhandled rejections and swallowed errors are both findings.
- **Degradation:** when a dependency is down, what still works? Fallbacks, circuit breakers, cached data, and queued work.
- **Scaling:** stateless servers, connection pooling, rate limits and quotas from vendors, in-memory state or local files that break with two instances, cron jobs that run twice, and what happens at 10x traffic.
- **Background work:** queues, dead-letter handling, safe re-runs, and jobs that survive a deploy.
- **Single points of failure** and graceful shutdown. Backups and restores for important data.

**Don't flag:** retry and scaling machinery for a tool that's local, single-user, or low stakes.

## errors

Proactive error handling means anticipating failure before a user reports it.

- Likely failures are handled: empty, null, and oversized input, expired sessions, network drops, permission denials, rate limits, partial failures, and double submits.
- Validate at every trust boundary with a schema, and fail early with a specific message.
- User-facing errors say what happened and what to do next, keep the user's input, and offer a retry when it would help. No stack traces or raw codes.
- Error boundaries in UI so one failure doesn't blank the page. Designed 404 and 500 pages.
- Errors carry enough context to debug, and each one is either handled or reported, never dropped.

## data

- **Integrity:** constraints, foreign keys, and uniqueness in the database rather than only in app code.
- **Transactions and rollback:** a multi-step write either fully happens or leaves no trace. Ask what state is left if any step fails partway.
  - Related writes share one transaction, and every error path rolls it back, including errors caught and handled in app code.
  - A database rollback can't undo outside effects like a charge, an email, or an API call. Run those after the commit, for example through an outbox, or define how each one gets undone, such as a refund.
  - A multi-step flow across services or jobs needs a way to undo or finish each step, and a failure partway can be resumed or cleaned up.
- **Concurrency:** race conditions and check-then-act bugs.
- **Idempotency:** most actions that change something should be safe to repeat, so a second request can't duplicate a payment, insert, email, or anything else. Walk each write and ask what happens on a double click, a refresh, a resend after a timeout, a redelivered webhook, or a re-run job.
  - Use whatever fits: an idempotency key, an upsert, a unique constraint, or a state check inside the same transaction. A repeat returns the first result rather than an error, where the caller can use it.
  - The database enforces it. A "does it exist yet?" check followed by an insert fails when two requests arrive together.
  - A key belongs to the user's one intent. It's created before the first attempt and reused on every retry, and it's passed on to payment and email providers that accept one.
- **Concurrent updates:** a save must not silently overwrite someone else's newer change. Check data that more than one user, tab, device, or background job can edit.
  - Version the data with a version number, `updated_at`, or ETag, and make each write conditional on the version it read.
  - Merge when you can. Send only the fields that changed, apply counters as increments and lists as adds and removes, and combine edits that don't overlap. Text that people edit together may need a CRDT or similar.
  - When two changes truly conflict, keep both and let the user choose, or apply a rule the product has chosen on purpose. Never lose the user's input.
- **Lifecycle:** deletion really deletes (or is deliberately soft), retention rules, and timezones, money, and precision stored correctly.

**Don't flag:** idempotency on reads or on writes that are already safe to repeat, or versioning on data that only one writer can ever touch.

## migrations

Mark this N/A if the project has no database. The database's structure should be fully rebuilt from the project's migrations, and its seed data should always match that structure.

**Used the way the framework intends**
- Every schema change, and any data change existing environments need, is in a migration. It uses the framework's own tool, naming, folder, and ordering.
- Production doesn't rely on automatic schema sync, such as `prisma db push`, `synchronize: true`, or `ddl-auto: update`.
- Generated migrations are reviewed, not trusted blindly, and migrations that already ran anywhere shared are never edited. A new one corrects them.
- Each migration has one purpose. Migrations from parallel branches can't collide or run in the wrong order.
- Migrations run in one defined deploy step, exactly once.

**Nothing was done by hand**

A change made directly to a database works until the next fresh environment fails. Look for:
- Models or code that expect something no migration creates.
- SQL or commands in PR notes, docs, chats, or one-off scripts that say to run them on a server.
- Items that are easy to change in a dashboard: indexes, functions, triggers, extensions, enums, grants, and access policies.

If it looks like something was run by hand, the finding names what should be in a migration, and asks a person to confirm what production really has.

**Safe on live traffic**
- No long locks. Large tables use the database's safe options, and backfills run in batches.
- Migrations are reversible or safely forward-only, and they can be deployed before the code that needs them. Risky changes roll out in stages: add the new, move over, then remove the old.
- New tables include their grants and access policies.

**Seeds stay in step**
- Every schema change updates the seeds: new required fields, renames, removals, new tables, relationships, and new enum values. Test factories and fixtures are updated too.
- New features get seed data, so a developer can see them working, across the plans, roles, and states that matter.
- Seeds can run twice safely, and can't run against production.
- Seeds use made-up data, with no real customer data or real secrets.
- Data production needs, such as roles or plans, lives in a migration or a separate production-safe seed, not in development seeds.

**Setup runs it all**

`make setup` or its equivalent starts what the app needs, such as Docker images, waits until those services are ready, then runs migrations and seeds. A single reset command rebuilds the local database from scratch.

**How to check:** if the project can run safely, use a throwaway database. Migrate from empty, seed, seed again, and run the framework's drift check, such as `prisma migrate diff`, `makemigrations --check`, or `doctrine:migrations:diff`. Never run this against a shared or production database. Whatever wasn't run is Not verified.

**Severity:** Critical or High for a migration that can lose data or lock production, and High for a change production has but migrations don't. Medium for seeds that fail or have fallen behind.

**When fixing:** write the migration or seed change, and test it only on a local throwaway database. A person decides when it runs anywhere shared.

**Don't flag:** old migrations that already ran, even if they'd be written differently today.

## operations

`resilience` judges how the code copes with failure. This lens judges what the code runs on, and how you'd recover when something serious happens.

**Build pipeline**
- CI actions and base images are pinned to a version or hash, and third-party steps get the least trust.
- CI tokens have the narrowest access that works, and secrets can't reach forks or logs.
- Releases are built by CI from a lockfile, not on someone's laptop.
- Containers use small maintained images, don't run as root, and keep secrets out of their layers.

**Hosting and access**
- Infrastructure is defined in code or written down, so it could be rebuilt.
- Cloud and vendor accounts use narrow access and MFA, with no shared logins, and people who leave lose access.
- Databases and internal services aren't open to the internet, and traffic uses TLS.
- Domains and certificates renew automatically, and someone owns them.

**Recovery**
- Backups are automatic and kept separately, and a restore has actually been tested.
- The project knows how much data it could lose and how long it could be down, and its setup can meet that.
- Single points of failure are known, including a vendor, a region, or the one person who knows how something works.

**Incidents**
- It's clear who owns production and how to reach them.
- Likely failures have runbooks.
- Someone can quickly roll back, turn off a feature, or block abuse.
- There's a way to tell customers during an outage.
- Serious incidents lead to a review and real fixes.

**How to check:** review what's in the repo, such as workflows, Dockerfiles, infrastructure code, and deploy config. Much of the rest lives outside it, so list what a person should confirm and mark it Not verified.

**Don't flag:** enterprise process for a small project. A solo product doesn't need an on-call rota, but it does need tested backups if it holds data someone would miss.
