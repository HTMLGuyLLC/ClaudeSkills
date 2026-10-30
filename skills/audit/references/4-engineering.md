# Group 4: Practices, quality, cost, delivery

## practices

**Framework first:** use the recommended approach instead of custom code. Check the current docs for the framework version in use. Examples: built-in routing, data fetching, forms, image handling, and auth helpers rather than hand-rolled versions.

**Build vs. buy:** flag a wrong choice in either direction.
- Write it yourself when it's simple and unlikely to change, such as a small helper that would otherwise pull in a package.
- Use a well-tested package when it's easy to get wrong or keeps changing: auth, crypto, dates and timezones, payments, parsing, sanitizing, email deliverability.
- Weigh package health, size, license, and the upkeep cost of each new dependency.

**General:** the right abstraction level, clear separation of concerns, no premature abstraction, and types used rather than bypassed (`any`, `@ts-ignore`, unchecked casts).

## quality

- **Not overly verbose:** say it in fewer lines when that's equally clear. Remove dead code, needless wrappers, and comments that repeat the code.
- **Not duplicative:** no large repeated chunks. Small repetition is fine; three real uses justify a shared helper. Use scanner output when available.
- **Current:** latest stable language features, APIs, and conventions. Flag deprecated functions and patterns the ecosystem has moved past.
- **Readable:** clear names, small focused functions, sensible file size, matches surrounding style, and no leftover debug code or stale TODOs.
- **Lint and types:** clean for the code in scope.

**Don't flag:** style preferences that the linter and repo don't enforce.

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
- **Compatibility:** public APIs, webhooks, file formats, and saved data keep working, or there's a versioned migration. Old clients and cached pages still work during a deploy.
- **Config:** new env vars are documented, in the example file, validated at startup, and set for every environment. Defaults are safe.
- **CI/CD and environments:** the build passes, deploy order is safe, and staging matches production where it matters.
- **Versioning:** version and changelog updates follow the project's release process.
