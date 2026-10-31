# Group 2: Performance, resilience, errors, data

## performance

**Page load**
- Core Web Vitals targets: LCP under 2.5s, INP under 200ms, CLS under 0.1. Measure with Lighthouse or the browser if the app can run; otherwise mark the numbers Not verified and review code only.
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

- **Migrations:** reversible or safely forward-only, safe on live traffic (no long locks), backfills handled, deployable before the code that needs them.
- **Integrity:** constraints, foreign keys, and uniqueness in the database rather than only in app code. Transactions around multi-step writes.
- **Concurrency:** race conditions, check-then-act bugs, lost updates, and double-charging or double-sending.
- **Idempotency** for webhooks, payments, and retried jobs.
- **Lifecycle:** deletion really deletes (or is deliberately soft), retention rules, and timezones, money, and precision stored correctly.
