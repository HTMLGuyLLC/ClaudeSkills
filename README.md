# Claude Skills

Free skills for [Claude Code](https://claude.com/claude-code). A skill is a command you type in Claude Code, like `/audit`.

Use them or fork them as you like. This repo doesn't take issues or pull requests, and it comes with no support. See [Install](#install) to get started.

| Skill | In one line |
|---|---|
| [`/audit`](#audit) | Checks your work for problems before you ship it |
| [`/loop-audit`](#loop-audit) | Checks your work, fixes what it finds, and repeats until it's clean |
| [`/personas`](#personas) | Builds a list of the people who use your product, and lets them debate decisions |
| [`/release`](#release) | Takes finished work all the way from commit to live release |
| [`/improve-deterministic`](#improve-deterministic) | Makes your rules-based logic more accurate, without AI in the final product |
| [`/cleanup`](#cleanup) | Clears out finished worktrees and branches, and asks before touching unfinished work |

## How to use each skill

### `/audit`

**What it does:** Reviews your code like a team of experts, covering security, speed, accessibility, design, legal, and more. It gives you a clear answer: Ship, Ship after fixes, or Don't ship. It doesn't change your code unless you ask.

**Choose what to check:**

| Command | What it checks |
|---|---|
| `/audit` | What you're working on now |
| `/audit pr 123` | A pull request |
| `/audit last 3` | Your last 3 commits |
| `/audit src/checkout` | One folder |
| `/audit all` | The whole repo |

**Choose which topics to check.** It runs all 34 unless you pick some. The list below shows what each one covers.

| Command | What it runs |
|---|---|
| `/audit security` | One topic |
| `/audit security,ux` | Several topics |
| `/audit protect` | One group of topics |

**Options:**

- `--quick` looks only for serious problems, and costs less.
- `--fix` also fixes the Critical, High, and Medium problems it finds.

```text
/audit pr 123 --quick
```

<details>
<summary><b>How it stays fast</b></summary>

- Its scanners, your lint, and your tests all run at the same time.
- For anything over 3 files, several reviewers work side by side and share one set of project notes, so they don't repeat the same research.
- Changes of 4 to 15 files use 3 reviewers, and bigger ones use up to 8. More reviewers means more tokens, and it tells you the estimate before it starts.
- Separate agents double-check a long list of serious findings.
- `--fix` makes unrelated fixes side by side.

</details>

#### What it checks

Every topic gets a result, so nothing is skipped silently. Click one to see what it covers.

**Protect** (`/audit protect`)

<details>
<summary><code>security</code>: Can someone break in, reach other people's data, or abuse the product?</summary>

- **Permissions:** every request checks on the server who you are and what you own, and new routes start closed.
- **Login and sessions:** rate limits, safe password resets, MFA, OAuth checks, secure cookies, and a logout that really ends the session. Any change here gets a line-by-line read of the whole flow.
- **Credentials and card data:** strong password hashing, secrets kept out of code and logs, keys with narrow access that can be rotated, and PCI rules that keep card numbers out of logs and databases.
- **File uploads:** provided filenames and file types are never trusted. It checks real file content against an allowlist, random server-side names, size limits, private storage, safe serving, and malware scans for shared files.
- **Common attacks:** the OWASP Top 10 lists for web, API, and AI apps, such as injection, XSS, SSRF, and formulas hidden in CSV exports, plus database access rules.
- **Dependencies and abuse:** known vulnerabilities, outdated or fake packages, spam, free plan abuse, prompt injection, and moderation for products with user content.

</details>

<details>
<summary><code>privacy</code>: Should you be handling this personal data at all?</summary>

- **Collect less:** each field and event has a real use, and optional details are really optional.
- **Keep it contained:** personal data stays out of logs, analytics, URLs, and AI prompts, and real customer data stays out of staging and seed files.
- **Limit who sees it:** staff access is limited by role and logged.
- **Keep it only as long as needed:** retention is enforced by real scheduled deletion.
- **Give people control:** export, correction, deletion, and withdrawing consent all really work, including at your vendors.

</details>

<details>
<summary><code>legal</code>: Are your policies and public promises still true?</summary>

- **Terms and privacy:** they exist, are linked at signup and payment, and match the data, vendors, cookies, retention, and prices you really have.
- **Every claim:** each one on your site and in your app, like "cancel anytime" or "99.9% uptime", is marked True, False, Stale, or Unproven.
- **Disclaimers:** added where the law or a real risk needs one, and removed where one only hurts the product.
- **Regional rules:** GDPR, US state privacy laws, the EU AI Act, accessibility law, and others that plausibly apply to you.
- **Licenses:** whether your packages, fonts, images, and data can be used the way you use them.
- **With `--fix`:** it corrects anything out of date right away, then lists each old and new wording for you to review. A new promise that would cost you time or money, like a refund, is raised in the chat first.

</details>

**Reliability** (`/audit reliability`)

<details>
<summary><code>correctness</code>: Does it do what was asked, and get the right answer?</summary>

- **The goal:** it finds what was asked from your request, the PR, linked issues, and commits, then checks every part was done.
- **Connected end to end:** the button calls the route, the route saves the field, and the value is still there after a reload.
- **Nothing half-built:** no stubs, placeholder values, or hardcoded test data.
- **Math and rules:** business rules, rounding, money, tax, and totals that match on every screen, email, and export.
- **Edge cases:** empty lists, limits, time zones, month ends, and inverted conditions.
- **How it checks:** it works out the right answer for a realistic example, then follows that example through the code.

</details>

<details>
<summary><code>performance</code>: Is it fast, and does it feel fast when it can't be?</summary>

- **Lighthouse:** real runs on key pages, on mobile and desktop, reporting LCP, INP, CLS, TTFB, FCP, TBT, and scores against set targets. Each miss is traced to its cause.
- **Page load:** server response, bundle size, images, fonts, and third-party scripts.
- **Queries and parallel work:** N+1 queries, missing indexes, results with no limit, calls that could run together, and fan-outs that need a limit.
- **Caching and background work:** the right cache, and slow work moved off the request.
- **How waits feel:** a like responds right away, a feed shows its layout first, a photo shows a blurred preview, a progress bar finishes fast, a file uploads while you write the caption, and a long search shows what it's doing.
- **Honesty:** a fake count, or a success message for something that failed, is reported as a problem.

Timing can only be judged in a running app.

</details>

<details>
<summary><code>resilience</code>: Does it keep working when something else fails?</summary>

- **Timeouts:** on every network, database, and AI call.
- **Retries:** limited, spaced out, and only for failures that might pass.
- **Outages:** what still works when a service you depend on is down.
- **Scaling:** whether it still works with two servers or 10 times the traffic.
- **Background jobs:** queues, safe re-runs, and jobs that survive a deploy.
- **Recovery:** single points of failure, clean shutdowns, backups, and restores.

</details>

<details>
<summary><code>errors</code>: When something goes wrong, does the user know what to do next?</summary>

- **Likely failures:** empty or oversized input, expired sessions, dropped connections, denied permissions, and double submits.
- **Validation:** input is checked at every entry point, and fails early with a specific message.
- **Error messages:** they say what happened and what to do next, keep what the user typed, and offer a retry when it helps.
- **Crashes:** one failure doesn't blank the page, and 404 and 500 pages are designed.
- **Nothing dropped:** each error is either handled or reported, with enough detail to debug.

</details>

<details>
<summary><code>data</code>: Can your data get lost, duplicated, or overwritten?</summary>

- **Rules:** constraints and uniqueness are enforced by the database, not only in code.
- **Failures leave nothing half done:** if a step fails partway, everything rolls back. Charges or emails a database can't undo run after the save, or have their own way to be reversed.
- **Repeats do no harm:** a double click, a retry, or a resent webhook can't charge someone twice or add a duplicate row.
- **Edits don't overwrite each other:** the newer change isn't silently lost. Changes that don't overlap are merged, and real conflicts keep both versions.
- **Lifecycle:** deleting really deletes, and dates, money, and precision are stored correctly.

</details>

<details>
<summary><code>migrations</code>: Can your database be rebuilt from your migrations and seeds?</summary>

- **Framework conventions:** every schema change is a migration, using your framework's own tool, naming, and order.
- **Nothing run by hand:** it looks for changes that were made directly to a database and should be in a migration, like an index, grant, or access policy.
- **Safe on live traffic:** no long locks, backfills run in batches, and risky changes roll out in stages.
- **Seeds kept in step:** every schema change updates seeds and test data, and new features get realistic seed data.
- **Safe seeds:** they can run twice, can't run against production, and hold no real customer data.
- **Setup runs it all:** `make setup` or similar starts things like Docker images, waits for them, then runs migrations and seeds.

If it can, it tests this on a throwaway database. It never runs anything against a shared or production database.

</details>

<details>
<summary><code>operations</code>: Is what runs your code safe, and could you recover?</summary>

- **Build pipeline:** CI steps and images are pinned, tokens have narrow access, and CI builds your releases.
- **Hosting and access:** infrastructure can be rebuilt, accounts use narrow access and MFA, and databases aren't open to the internet.
- **Domains and certificates:** they renew automatically, and someone owns them.
- **Recovery:** backups are automatic and a restore has been tested, and you know how much data and downtime you could lose.
- **Incidents:** there's a clear owner, runbooks, a fast way to roll back or turn something off, and a way to tell customers.

Much of this lives outside the repo, so it lists what you need to confirm. Small projects aren't held to enterprise process.

</details>

**Observability** (`/audit observability`)

<details>
<summary><code>logging</code>: Could you work out what happened from your logs?</summary>

- **Coverage:** logins, payments, permission changes, failed outside calls, job results, and admin actions.
- **Structure:** each entry has a level, a request ID, and enough detail to debug.
- **Levels:** errors are worth acting on, and normal traffic isn't logged as an error.
- **Safety:** no secrets, card data, or needless personal data.
- **Volume:** your existing logger is used, without noisy logging in hot loops.

</details>

<details>
<summary><code>alerting</code>: Would you find out before a customer tells you?</summary>

- **Errors:** they reach a tracker or pager, not just a log file.
- **What hurts:** alerts for downtime, failed payments, failed jobs, error spikes, slow responses, quotas, and expiring keys.
- **Silent failures:** a job that stops running sends no errors, so it needs a heartbeat.
- **Noise:** each alert is worth acting on, goes to someone who would act, and links to what to do.
- **Uptime:** production services have health checks and monitoring.

</details>

<details>
<summary><code>tracing</code>: If something breaks, could you work out what happened?</summary>

- **The 3am test:** it imagines your riskiest path failing for one customer, then tries to follow the trail from the alert to the cause. Each dead end is a finding.
- **Following one request:** one ID links the browser, API, jobs, webhooks, and outside calls, and connects your logs, errors, and traces.
- **APM:** speed and error rates for each route, job, and outside service, with slowest-case timings, queue backlogs, and signals like checkouts per minute.
- **What changed:** deploys, migrations, feature flags, and config changes are recorded, and errors show their release and readable stack traces.
- **Rebuilding the story:** record history, job and webhook results, why an automated decision was made, what an AI call did, and a safe view of a customer's state for support.
- **Safe and affordable:** no secrets or needless personal data in traces, every error kept when sampling, and costs kept bounded.

Local or low-stakes tools don't need all of this. Whether data really arrives needs a running app or access to your tools.

</details>

<details>
<summary><code>analytics</code>: Can you tell whether a feature works?</summary>

- **Feature events:** new features show adoption, completion, and drop-off.
- **Funnels:** signup, activation, upgrade, and churn are measured end to end.
- **Naming:** events follow your existing names, with no duplicates.
- **Privacy:** consent is respected, personal data stays out, and vendors match your privacy policy.
- **Segments:** results can be split by plan and customer type.

</details>

<details>
<summary><code>tests</code>: Would your tests catch a real bug?</summary>

- **Unit:** new logic, edge cases, and a test for every bug fix.
- **Integration:** API routes, the database, auth rules, webhooks, and key user flows.
- **Performance:** load tests on busy paths, and size or speed budgets where they matter.
- **Quality:** tests check behavior, aren't flaky, and don't mock away what they should prove.
- **AI features:** evals for output quality, plus provider failures and malformed output.
- **CI:** tests run before merge, and nothing is skipped without a reason.

</details>

**Engineering** (`/audit engineering`)

<details>
<summary><code>practices</code>: Is this the right way to build it?</summary>

- **Framework first:** built-in routing, forms, images, and auth instead of custom code, checked against the current docs.
- **Build or buy:** small helpers are written by hand, and hard things like auth, crypto, dates, and payments use a tested package.
- **New packages:** health, size, license, and upkeep are weighed.
- **Structure:** the right level of abstraction, with types used rather than bypassed.

</details>

<details>
<summary><code>quality</code>: Is the code short, clear, well organized, and current?</summary>

- **Not too long or repeated:** no needless wrappers, comments that repeat the code, or large copied chunks.
- **Dead and orphaned code:** unreachable or unused code, plus code that still builds but nothing reaches, like files nothing imports, pages with no link, endpoints no client calls, and jobs nothing schedules.
- **Short flows:** routes, jobs, and pages read like a short list of steps, with the details in named functions and classes they call.
- **File structure and size:** classes, large functions, and shared types get their own files, and each file has one job. This loads less into an AI's context, causes fewer merge conflicts, and makes logic easier to scan, reuse, remove, or put behind a feature flag.
- **Current:** latest stable features, with nothing deprecated.
- **Readable and clean:** clear names, small functions, no leftover debug code, and passing lint and type checks.

</details>

<details>
<summary><code>leftovers</code>: Is anything here left over or just not needed?</summary>

- **Earlier attempts:** it reads the branch's commits for things added early and later abandoned, then checks whether they ever reached production.
- **Things that never shipped:** shims, fallbacks, and comments that mention a name, column, or approach that only existed during the work. These can send the next reader looking for something that was never there.
- **Stale extras:** temporary `v2` or `new` names, unused flags, settings, and packages, and leftover scripts, sample data, and tests.
- **Repetition:** two ways of doing one job, repeated checks, and options with only one value.
- **For users:** repeated messages, UI that restates the obvious, and steps that add nothing.
- **Safe removal:** it searches for every reference first, and leaves anything it can't prove is unused for you to decide.

</details>

<details>
<summary><code>cost</code>: Are you paying more than you need to, especially for AI?</summary>

- **AI as a fallback:** whether a rule, lookup, or query could do the job, fully or for the common cases.
- **Cheap first:** simple checks run first, and AI handles only what's left.
- **Efficient use:** the cheapest model that works, with caching, batching, and output limits.
- **Spend limits:** per-user and overall caps, so one user or a loop can't run up the bill.
- **Plan margins:** usage is measured, and each plan's price covers its AI cost.
- **Other spend:** costly queries, storage, bandwidth, email, SMS, and idle compute. If other sites could run up your bandwidth by embedding your files, it suggests hotlink protection, which is your choice to make.

</details>

<details>
<summary><code>delivery</code>: Can this ship safely, and be undone?</summary>

- **Rollout:** risky changes sit behind a flag, and can be rolled back along with their data.
- **Backward compatibility:** APIs, webhooks, and saved data keep working, including during a deploy.
- **Deprecation:** removing something customers rely on comes with notice, a date, and a way forward.
- **Config:** new settings are documented, checked at startup, and set everywhere.
- **Environments:** the build passes, deploy order is safe, and staging matches production where it counts.
- **Versioning:** versions and the changelog follow your release process.

</details>

**Experience** (`/audit experience`)

<details>
<summary><code>a11y</code>: Can everyone use it?</summary>

- **Standard:** WCAG 2.2 AA at minimum, plus AAA where it's cheap.
- **Keyboard:** everything works without a mouse, with visible focus and no traps.
- **Screen readers:** real HTML structure, labels, alt text, and announced updates.
- **Contrast:** checked in both light and dark themes.
- **Forms:** visible labels, and errors tied to their fields and not shown by color alone.
- **Size and motion:** large enough targets, text that resizes, and reduced-motion settings respected.

Contrast and focus order need a running app to confirm.

</details>

<details>
<summary><code>compatibility</code>: Is there a clear target, and does all the code work on it?</summary>

- **A set target:** browsers, devices, operating systems, and runtimes are written down in one place, and your tools and docs agree with it.
- **Choosing one:** if there isn't a target, it proposes one from your usage data or customers. You make the final call, even with `--fix`.
- **Code complies:** new JavaScript APIs, CSS, web features, and native APIs are checked against current browser support data, not memory.
- **Dependencies:** each package works on your target too.
- **Failing well:** features are detected properly, and an unsupported browser gets a clear message or a working fallback, not a blank page.
- **Not too far back:** it flags polyfills and workarounds for versions you don't need to support.

Proving it works needs a run on your oldest targets, and anything that wasn't run is marked Not verified.

</details>

<details>
<summary><code>simplicity</code>: Is it easy to understand and quick to set up?</summary>

- **Words:** plain enough for beginners, without talking down to experts.
- **Labels:** they say what things do, and empty states and errors point to the next step.
- **Setup:** good defaults, with steps to first value counted and trimmed.
- **Options:** advanced settings stay out of the way, and ones that don't earn their place are removed.
- **Local setup:** a new developer or AI agent gets from a fresh clone to a running app in as few commands as possible. Ideally that's `make setup` then `make run:dev`, or `make setup`, `make build`, and `make run`. A task runner like `make` keeps commands the same across stacks, but it isn't required. In most cases setup should be idempotent, so it can be rerun without errors, duplicates, or lost local data.

</details>

<details>
<summary><code>consistency</code>: Does everything match everywhere?</summary>

- **Wording:** a changed term is updated in code, UI, docs, emails, and marketing, with one name for each idea.
- **Naming:** variables, files, routes, columns, and events follow the same conventions.
- **Design:** the same tokens, components, and patterns for the same jobs.
- **Architecture:** the same job is done the same way across the codebase.
- **Ideals:** decisions match what the product says it stands for.
- **Sibling fixes:** a bug fixed in one place is fixed in its copies too.

</details>

<details>
<summary><code>docs</code>: Did this change make anything out of date?</summary>

- **Repo docs:** the README, setup steps, screenshots, changelog, and other markdown.
- **Customer help:** the help center, in-app help, tooltips, and onboarding.
- **Developer docs:** API docs, SDK examples, and settings references.
- **Marketing:** the blog, feature lists, pricing, and emails.
- **Outside the repo:** anything it can't reach is listed for you to update.
- **Changelogs:** each public changelog or What's new shows only what its readers can see or experience. Admin and marketing site updates stay out of customer changelogs, and so do refactors and other behind-the-scenes work. Routine security patches stay out too, unless the issue was serious, users were affected, or they need to act. Developer changelogs for libraries and APIs are exempt.

</details>

<details>
<summary><code>ux</code>: Does each page guide people to the right action?</summary>

- **Attention:** what the eye lands on first, second, and third, and whether a new visitor gets the point within 5 seconds.
- **Main buttons:** one clear primary action per page, with labels that say what happens next and no dark patterns.
- **Layout and states:** clear hierarchy, few choices at once, people always know where they are, and loading, empty, error, and offline states plus first-time use are all designed.
- **Light and dark mode:** both are designed, including logos, charts, and emails, with no flash of the wrong theme.
- **Mobile:** every width from 320 up, thumb reach, no hover-only features, and forms that work with the on-screen keyboard.
- **Translation:** text, dates, and layouts work in each language you support.

Judging how things look needs a running app or screenshots.

</details>

<details>
<summary><code>seo</code>: Can search engines and AI assistants find and cite you?</summary>

- **Find and read:** important content is in the HTML the server sends, because many AI crawlers don't run JavaScript. Also `robots.txt`, sitemaps, canonical URLs, redirects, and accidental `noindex`.
- **AI crawlers:** allowing or blocking them is a deliberate choice, and bot protection doesn't quietly hide your site from AI answers.
- **Understand:** unique titles and headings, valid structured data, alt text, share previews, and `hreflang`.
- **Worth citing:** pages answer real questions directly, with specific facts that match across your site, docs, and listings.
- **Measured:** search tools are set up, and someone checks what AI assistants say about the product.
- **Fair play:** keyword stuffing, hidden text, and tricks aimed at AI tools are reported as problems.

Rankings and AI citations can't be proven from code, so they're marked Not verified.

</details>

**Product** (`/audit product`)

<details>
<summary><code>personas</code>: How does this feel to each type of customer?</summary>

- **Walkthroughs:** it goes through the change as each person, with their goals and limits.
- **Report:** what worked, and where they got stuck, confused, or let down.
- **Choosing who:** 4 to 8 people for an ordinary change, and everyone who fits for a release or full audit.
- **First run:** `/personas` works out who your users are, and later audits reuse that list.
- **Gaps:** it suggests any kind of user the list is missing.

These are informed walkthroughs, not real user research.

</details>

<details>
<summary><code>admin</code>: Can your team handle this change from the admin panel?</summary>

- **Coverage:** for anything that changes for a customer, staff can see it, handle it, and put it right without a developer.
- **Finding things:** new statuses and fields appear in admin lists, search, and filters, and don't break existing pages.
- **Safety:** staff actions check their role, confirm before anything destructive, and are logged. Passwords, card numbers, and private content stay hidden.
- **Admin panel in this project:** a normal finding, and `--fix` updates it.
- **Admin panel in another project:** a reminder listing exactly what's needed, so you don't forget. `--fix` never touches it, but you can tell the audit to make the change if it can reach that project, or take the brief there yourself.
- **Can't find one:** it asks you where it is, and can save the answer in `.claude/audit.md`.

</details>

<details>
<summary><code>plans</code>: Do your plans and billing work the way you say?</summary>

- **Gating:** enforced on the server, not just hidden in the UI.
- **Limits:** clear before people reach them, and hitting one explains what to do.
- **Billing paths:** upgrade, downgrade, cancel, expired trial, failed payment, and refund all work and keep data intact.
- **Accuracy:** pricing and feature lists match what each plan really gets.
- **Placement:** new features go in a plan on purpose, and the free plan stays affordable.

</details>

<details>
<summary><code>ai</code>: Can people trust your AI features?</summary>

- **Accurate:** evals on realistic examples run again when a prompt or model changes, and the feature can say it doesn't know.
- **Safe:** risky output gets a human review, and AI actions are limited and can be undone.
- **Fails well:** outages, refusals, and malformed answers are handled, and users keep their work.
- **Keeps working:** model retirement dates are known, and prompts are versioned with the code.
- **Honest with users:** AI output is labeled where needed, and users can correct or report a bad result.

This is skipped if your product doesn't use AI.

</details>

<details>
<summary><code>notifications</code>: Do your messages arrive, and do people want them?</summary>

- **They arrive:** email domain setup like SPF, DKIM, and DMARC, handled bounces, and visible failed sends.
- **Right message, right time:** no duplicates or late warnings, with digests for bursts and respect for quiet hours.
- **People stay in control:** preferences by type and channel, and one-click unsubscribe.
- **They read well:** templates work on phones and in dark mode, and a missing value never shows `Hi {{name}}`.
- **Safe test sends:** development and staging can't message real customers.

This covers email, SMS, push, and in-app messages.

</details>

<details>
<summary><code>api</code>: Are your API, MCP server, CLI, and SDKs good to build on?</summary>

- **Kept in step:** a new feature reaches each surface it belongs on, using shared logic and the same names. If a surface lives in another project, you get a reminder, just like `admin`.
- **API:** consistent patterns and errors, pagination, rate limit headers, safe retries, a spec that matches reality, and signed webhooks.
- **MCP server:** tools match real jobs, with clear descriptions, strict inputs, short results, helpful errors, and the signed-in user's permissions.
- **CLI:** `--help` everywhere, `--json` output, exit codes that mean something, no prompts in scripts, and `--dry-run` on risky commands.
- **SDKs:** feel natural in each language, handle retries and pagination, and are generated or tested so they can't drift.
- **Easy to start:** a quick start and examples that run as written.

</details>

<details>
<summary><code>innovation</code>: What could make this feel slick?</summary>

- **Less effort:** smart defaults, inference, or import in place of forms and setup steps.
- **AI that saves work:** natural-language input, summaries, drafts, and suggestions.
- **Proactive help:** noticing what someone is trying to do, and doing the next step.
- **New technology:** passkeys, on-device AI, agent access, and real-time collaboration.
- **What you get:** 3 to 5 ideas at most, each with its benefit, effort, and running cost.

These are ideas, so they never block shipping.

</details>

### `/loop-audit`

**What it does:** Runs `/audit`, fixes what it finds, and audits again, until only rare, minor issues are left. Anything that needs a human decision goes on a list for you. It doesn't commit unless you ask. This one can use a lot of tokens, and it tells you the worst case before it starts. Each round reuses the first round's project notes, runs your tests while the reviewers read, and makes unrelated fixes side by side.

**Audit and fix your current work:**

```text
/loop-audit
```

**Stick to one topic, or limit the rounds (the default limit is 5):**

```text
/loop-audit security --max 3
```

### `/personas`

**What it does:** Makes one list of the people who use and support your product, such as free customers, big companies, support agents, and the owner. It reuses any personas you've already written, and asks you which to keep. Then it saves them to `.claude/personas.md`, so nothing has to make them up again.

**Create your list, or check an existing one for gaps:**

```text
/personas
```

**Add someone:**

```text
/personas add a school admin who manages 200 students
```

**Have them debate a decision:**

```text
/personas debate what should be included in the pricing page
```

```text
/personas debate how can we improve the homepage
```

```text
/personas debate would it be useful to add team workspaces
```

The personas each give their view alone, argue with each other, then vote on a proposal. You get a recommendation, or an honest "they couldn't agree". The result shows who still disagrees and what a person needs to decide. Everyone reads the same saved fact sheet, which keeps the debate fair and saves tokens. A full report goes in `.claude/debates/`.

**Debate options:**

- `--with` picks who debates, up to 7.
- `--quick` is cheaper, but one AI plays everyone, so the views aren't independent.

```text
/personas debate should we drop the free plan --with "Free plan customer, Owner, Support agent"
```

These debates are simulated by AI from your project's files. They help you think, but they aren't real user research. A debate never changes your code.

### `/release`

**What it does:** Ships your work from start to finish. It commits, opens a PR, waits for tests and reviews, fixes what comes back, merges, and runs your project's release process. If it gets stuck or stops partway, run it again and it picks up where it left off. When CI fails or reviews come back, it gathers everything at once and fixes it all in one push, because every push restarts CI. If your project has a public changelog, it adds only what those readers can see or experience.

**Ship it:**

```text
/release
```

**Choose the version number:**

```text
/release minor
```

```text
/release 2.0.0
```

You can use `patch`, `minor`, `major`, or an exact version.

**Stop early:**

```text
/release --no-release
```

```text
/release --no-merge
```

- `--no-release` merges the PR, but doesn't publish a release.
- `--no-merge` gets the PR ready, but leaves merging to you. It doesn't publish a release either.

### `/improve-deterministic`

**What it does:** Improves plain code or rules, like a spam filter or a support ticket sorter, by testing them against real examples. AI helps while you develop, but the finished logic has no AI in it, so it's cheap and predictable to run. It keeps a change only if the score really improves. Big labeling jobs run in parallel batches, and unrelated fixes can be tried side by side. Each one is still tested alone before it's kept.

**Improve something:**

```text
/improve-deterministic the spam filter
```

**Stop at a score or a number of rounds (the default limit is 10 rounds):**

```text
/improve-deterministic the ticket sorter --target 95 --max 5
```

**Remove its test data when you're done:**

```text
/improve-deterministic cleanup spam-filter
```

Its data stays in a `.improve/` folder that git ignores. That folder may hold private data, and it asks before copying or deleting anything private.

### `/cleanup`

**What it does:** Reviews the git worktrees in every repo Claude has worked in. It removes the ones whose work is merged and that nothing is using, along with merged branches and dead worktree records. It shows you anything unfinished and asks first, and it never touches a worktree that a chat or process is using. It fetches your repos at the same time, up to 8 at once, to shorten the scan.

**Clean up everything:**

```text
/cleanup
```

**See what it would do, without removing anything:**

```text
/cleanup --dry-run
```

**Check one repo:**

```text
/cleanup ~/code/my-app
```

**Do only the safe removals, and list the rest for later:**

```text
/cleanup --no-ask
```

Commits that only a detached worktree holds are saved to a `rescue/` branch before it's removed. If you remove unfinished work and keep it, the branch stays and uncommitted changes go to a stash. It never deletes remote branches or chat history. Full detection needs the Claude desktop app on a Mac, and it works from `git` alone elsewhere. If `lsof` is missing, it can't see running processes, so it asks before removing anything.

## Install

You need [Claude Code](https://claude.com/claude-code) and `git`. `/cleanup` also needs `jq`. Download the repo, or your own fork of it:

```bash
git clone https://github.com/HTMLGuyLLC/ClaudeSkills.git ~/ClaudeSkills
```

Then link the skills into Claude Code:

```bash
~/ClaudeSkills/install.sh
```

`install.sh` links each skill into `~/.claude/skills/`, so edits in the repo apply right away. It never replaces a folder, a file, or a link that points somewhere else. It lists those and exits with an error so you can move them aside. The links point at this folder, so keep it where it is.

### Update

```bash
git -C ~/ClaudeSkills pull
```

Run `install.sh` again if a new skill was added.

### Optional tools

`/release` and `/audit pr` need the [GitHub CLI](https://cli.github.com), signed in with `gh auth login`.

`/audit` uses more scanners if they're installed. None are required:

```bash
brew install gitleaks osv-scanner semgrep shellcheck
```

Without Homebrew, see each tool's install page.

`/audit` also runs Lighthouse on your pages if it's installed and your app can run:

```bash
npm install -g lighthouse
```

## Add a skill

1. Create `skills/<name>/SKILL.md`.
2. Run `./install.sh`.
3. Run `tests/run.sh`.
4. Commit and push.

To remove a skill, delete its folder here and its link in `~/.claude/skills/`.

## Tests

`tests/run.sh` checks the scripts offline, using a stub `gh`, temporary repos, and a temporary `HOME`. It needs only `git` and `jq`, and CI runs it on every push.

## License

[MIT](LICENSE)
