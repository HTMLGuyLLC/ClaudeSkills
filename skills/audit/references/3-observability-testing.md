# Group 3: Logging, alerting, tracing, analytics, tests

## logging

- Important events are logged: auth, payments, permission changes, external failures, background job results, and admin actions (audit trail).
- Logs are structured, with level, a request or correlation id, and enough context to debug without reproducing.
- Levels fit: errors are actionable, and normal traffic isn't logged as an error.
- No secrets, tokens, card data, or unnecessary personal data in logs.
- The repo's existing logger is used, rather than stray `console.log` or `print`.
- Volume is reasonable, with no per-item logging in hot loops, and retention suits the cost.

## alerting

Logging only helps if someone finds out. For each new failure mode, ask: how would we know within minutes, before a customer tells us?

- Errors reach a tracker or pager (Sentry or similar), not just a log file.
- Alerts exist for what hurts: downtime, failed payments, failed background jobs, webhook failures, error-rate spikes, slow responses, quota or budget limits, and expiring certificates or keys.
- Silent failures are covered: a job that stops running produces no errors, so it needs a heartbeat or dead-man's switch.
- Alerts are actionable and go to someone who'd act. A noisy alert is a finding too.
- Health checks and uptime monitoring exist for production services.

## tracing

`logging` judges what gets written, and `alerting` judges whether someone finds out. This lens asks what happens next: could someone work out what went wrong, where, why, and for whom, using production data alone? They shouldn't have to reproduce it, or add code and redeploy.

**Start with the drill.** Take the riskiest path in scope and imagine it failing for one customer at 3am. Start from an alert or a support ticket, then try to find that exact request, follow each step, see where it broke, and tell what changed. Each place the trail goes cold is a finding, and it should say what question couldn't be answered.

**Following one request**
- One ID follows the work across every hop: browser, API, queues, background jobs, webhooks, and outside calls. It travels in headers and job payloads, using W3C Trace Context where it fits. Async boundaries are where it usually gets lost.
- Spans cover what takes time or fails: database queries, outside calls, AI calls, and time waiting in a queue, each with a status and duration.
- OpenTelemetry, or the instrumentation the framework or vendor already provides, is used rather than something hand-rolled.
- Logs, errors, and traces share the ID, so one leads to the others.
- A user can give support something to search: error pages show a reference ID, and browser failures link to the backend request behind them.

**APM and metrics**
- Each route, job, and dependency shows its rate, error rate, and duration.
- Latency is read as p95 and p99, because an average hides the slowest customers.
- Each outside service can be seen on its own, so "the app is slow" can become "this vendor is slow".
- Saturation shows before it hurts: queue depth and oldest job age, connection pools, memory, and CPU.
- Business signals exist for key flows, such as checkouts per minute. They catch failures that still return a 200.

**Error context**
- Production stack traces are readable, with source maps or symbols uploaded for each release.
- Errors carry the release, environment, request ID, user or tenant ID, and active feature flags, and they're grouped so one bug isn't a thousand reports.

**What changed**
- Deploys, migrations, feature flag changes, and config changes are recorded with a time and an author, so a spike can be matched to its cause.
- Telemetry carries the release or commit, so a problem can be tied to the version that introduced it.

**Reconstructing what happened**
- Important records keep a history of who or what changed them, when, and from what value.
- Job runs keep their attempts and results. Webhooks in and out keep their delivery status and can be replayed.
- Automated decisions can be explained, such as why someone was charged, blocked, rate limited, or flagged, including the rule or version that decided.
- AI calls record the model, prompt version, tokens, latency, cost, and tool calls, so a bad answer can be traced to what produced it.
- Support and admins can see a customer's state through a safe, logged, read-only view rather than querying production.
- Customers can see it too where they depend on it: the status of long-running work, and a status page for outages.

**Enough detail when it's needed**
- Detail can be turned up without a deploy, for example debug logging for one customer.
- Sampling keeps every error and slow request.
- Retention outlasts the time it takes bugs to get reported, not just a day or two.

**Safe to run**
- No secrets, tokens, card data, or unneeded personal data in spans, attributes, URLs, or stored prompts. Access to this data is limited.
- Vendors that receive it match the privacy policy.
- A telemetry failure can't break the request.
- Volume and cost are bounded, with no user IDs or other unbounded values as metric labels.

**How to check:** if the app runs, force a failure and follow it through the tools. Code can show that instrumentation exists, but not that data arrives or that dashboards are useful, so mark those Not verified without access.

**Don't flag:** distributed tracing for a single process with no outside calls, metrics or dashboards with no question behind them, instrumenting every function, or a full setup for a tool that's local, single-user, or low stakes. There, a clear error and a useful log are enough.

## analytics

- New features fire events that show whether they work: adoption, completion, drop-off.
- Key funnels are measured end to end: signup, activation, upgrade, churn.
- Event and property names follow the existing convention, with no duplicate events under new names.
- Consent is respected, personal data isn't sent to analytics, and vendors match the privacy policy.
- Plan and persona can be segmented, so results can be read per customer type.

**Don't flag:** tracking with no decision behind it. Fewer meaningful events beat more events.

## tests

Follow the repo's framework and layout. Judge tests by what they would catch.

- **Unit:** new logic, branches, edge cases, and bug fixes (each fix has a test that would have failed before it).
- **Integration:** real boundaries such as API routes, the database, auth rules, webhooks, and critical user flows end to end.
- **Performance:** load or benchmark tests on hot or high-risk paths, and budgets for bundle size or response time where the project cares.
- **Quality:** tests assert behavior rather than implementation, aren't over-mocked to the point of proving nothing, aren't flaky, and have clean setup.
- **AI features:** output quality has evals, and tests cover provider failure and malformed output.
- **CI:** tests run before merge, and nothing is skipped or disabled without a reason.

**Don't flag:** missing tests for trivial glue, generated code, or throwaway scripts.
