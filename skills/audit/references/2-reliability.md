# Group 2: Performance, resilience, errors, data

## performance

**Page load**
- Core Web Vitals targets: LCP under 2.5s, INP under 200ms, CLS under 0.1. Measure with Lighthouse or the browser if the app can run; otherwise mark the numbers Not verified and review code only.
- Bundle size, code splitting, unused or heavy dependencies, render-blocking scripts, third-party tags.
- Images and fonts: modern formats, sizes, lazy loading, `font-display`.
- Server rendering, static generation, and caching used where the framework supports them.

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

**Don't flag:** micro-optimizations on cold paths, or speculative caching that adds more risk than it saves.

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
