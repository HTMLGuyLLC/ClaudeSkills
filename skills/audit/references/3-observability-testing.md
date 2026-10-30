# Group 3: Logging, alerting, analytics, tests

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
