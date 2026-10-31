# Group 6: Personas, admin, plans, AI, notifications, API, innovation

## personas

Walk through the changed experience as each person on the list, in their shoes and with their constraints. Ask what they'd notice, want, or get stuck on. This finds what code review misses.

**Choose the personas.** Use only the list in your brief, and don't invent your own. Pick by each persona's `Areas` and by what the change touches. Include team personas when it touches something they rely on, such as admin pages, support tools, reports, or seeded test accounts.

Use a representative 4 to 8 personas for an ordinary change, and all that fit for a release or full audit. Skip personas the change can't affect, with a reason.

**For each persona, report:** their goal, the path they took, what worked, and where they got stuck, were confused, or felt let down. Findings must point to actual behavior in code or copy. Don't invent user opinions or claim research that didn't happen. These are informed walkthroughs, not user testing.

**Spot gaps.** If the code shows a kind of user nobody on the list covers, such as a new role or plan, return it as a suggested persona with the evidence. A suggestion isn't a finding.

## admin

Anything that changes for a customer should also be something the team can handle from the admin panel. If it isn't, the first support ticket about it needs a developer and a database query, or leaves the customer stuck.

**Find what changed for customers:** new or changed data, settings, account or subscription states, permissions, limits, plans, credits, and actions. For each one, ask whether staff can do these from the admin panel:
- **See it:** the current value or status for one customer, without querying the database.
- **Handle it:** what support will need, such as change, reset, retry, grant, cancel, refund, or turn on and off for that customer.
- **Recover it:** put things right when this gets stuck or goes wrong.
- **Find it:** new statuses and fields appear in admin lists, search, and filters. A new value doesn't show blank or crash an existing admin page.
- **Do it safely:** actions check the staff member's role on the server, confirm before anything destructive, and write to the audit log.

**Find the admin panel.** Check the `## Admin panel` section of `.claude/audit.md`, then the project's docs, then search the repo for admin routes, apps, back-office tools, and framework admin setups. Then treat the result as one of these:

| Where it is | What to do |
|---|---|
| In this project | Report a normal finding, with the admin code to change. Use `file:line` of the closest admin page or route |
| In another project or tool | Return a finding marked `Elsewhere`. It's a reminder for the user, not a defect in this code. Don't read or change that project |
| Can't tell | Mark the lens Not verified, and say the user should be asked where it is |
| Confirmed there isn't one | Mark the lens N/A if `.claude/audit.md` says so with a reason. Otherwise, report one Idea if support clearly needs a panel |

**Write an `Elsewhere` finding so someone new can act on it:** what changed for customers, what the admin panel needs to show or do, the fields, API, or migration it depends on, and whether it has to ship before or after this change.

**Severity:** usually Medium. Use High when a problem with a customer's money or access can't be solved without a developer.

**Don't flag:** changes customers can't notice, or preferences support would never touch. Don't ask for edit controls where a read-only view is safer. Staff should never see passwords or full card numbers, and private customer content should stay hidden unless the product has a clear reason and a logged way to access it.

## plans

- Gating is enforced on the server, not just hidden in the UI.
- Limits are clear before the user hits them, and hitting one explains what happened and what to do.
- Upgrade, downgrade, cancel, expired trial, failed payment, and refund paths work and leave data intact.
- Pricing and feature lists match what each plan really gets.
- New features are placed in a plan on purpose, and the free plan's cost stays sustainable.

## ai

Mark this N/A if the product doesn't use AI. Prompt injection and tool access are covered by `security`, spend by `cost`, and tracing of AI calls by `tracing`. This lens asks whether people can trust the feature.

**Accurate**
- Quality is measured with evals on realistic examples, including hard ones, and they run again when a prompt or model changes.
- Answers that depend on facts are based on real sources, and citations point to something real.
- The feature can say it doesn't know, rather than making something up.
- Structured output is checked against a schema before it's used.

**Safe**
- Risky output gets a human review before it takes effect, such as anything touching money, health, legal matters, or messages sent to people.
- Actions the AI takes are limited, and can be confirmed or undone.
- Decisions about people are checked for unfair bias.

**Fails well**
- An outage, rate limit, timeout, refusal, cut-off answer, or malformed output is handled, and the user keeps their work.
- A fallback model or a non-AI path exists where the feature matters.

**Keeps working**
- Models are named on purpose, and their retirement dates are known.
- Prompts are versioned with the code, so a change can be reviewed and rolled back.
- Long inputs are handled before they hit context limits.

**Honest with users**
- AI output is labeled where the law or the situation calls for it, and claims about it are realistic.
- Users can correct a bad result or report it, and that feedback reaches the team.

**Don't flag:** full evals or human review for low-stakes output, such as a suggested title the user can just change.

## notifications

This covers email, SMS, push, and in-app messages. Mark it N/A if the product sends none.

**They arrive**
- Email domains have SPF, DKIM, and DMARC, and marketing mail doesn't put transactional mail at risk.
- Bounces and complaints are handled, and failed sends are retried or visible to the team.
- SMS sender registration is done where carriers require it.

**The right message at the right time**
- Each one comes from a real event, and repeats don't send it twice.
- It's still true when it arrives, and a problem that's already solved doesn't trigger a late warning.
- Bursts are grouped into a digest, and quiet hours and time zones are respected where they matter.

**People stay in control**
- Preferences exist by type and channel, and unsubscribing works in one click.
- Required messages, like receipts and security alerts, are kept separate from marketing.
- An opt-out applies everywhere it should, and quickly.

**They read well**
- Templates work in major email clients, on phones, and in dark mode, with a plain-text version.
- A missing value shows a sensible fallback, never `Hi {{name}}`.
- Links work and go to the right environment, and sensitive details stay out of subject lines and lock screens.
- The sender is recognizable.

**Test sends are safe:** development and staging can't message real customers.

**Don't flag:** preference settings for a product that only sends required messages, such as password resets.

## api

This covers every way other people's code or AI agents use the product: its API, MCP server, CLI, SDKs, and webhooks. Mark it N/A if there are none. Design matters as much here as in any UI, because these users can't work around a bad one. Security is covered by `security`, keeping old versions working by `delivery`, and stale docs by `docs`.

**Across all of them**
- **Kept in step:** a new or changed product feature reaches each surface it belongs on. Flag one that lags. If a surface lives in another project, return a finding marked `Elsewhere`.
- **One core:** each surface is a thin layer over shared logic, so rules, permissions, and limits can't drift apart.
- **Same words:** a concept has the same name everywhere.
- **Easy to start:** a quick start works, and examples run as written.
- **Helpful failures:** errors are consistent, can be read by code, and say how to fix the problem.
- **Clear versions:** changes follow a stated versioning policy, and changes are announced.

**API**
- Names, methods, and status codes follow one pattern.
- Lists have pagination and filters, and rate limits are shown in headers.
- Writes can be retried safely, and keys can be limited by scope.
- Any published spec, such as OpenAPI, matches what the API really does.
- Webhooks are signed, retried, and versioned, and can be replayed.

**MCP server**
- Check it against the current MCP spec.
- Tools match jobs users want done, with clear names and descriptions an AI can choose from, rather than one tool per endpoint.
- Inputs have strict schemas.
- Results are short and useful, so they don't fill an AI's context, and long lists have pagination.
- Errors tell the agent what to do next.
- Tools act as the signed-in user, with that user's permissions.
- Tools that delete or change things are marked as such and need confirmation.

**CLI**
- Every command has `--help`, and commands and flags stay stable.
- It works without prompts in scripts, with exit codes that mean something, results on stdout, messages on stderr, and `--json` output.
- Risky commands confirm first and offer `--dry-run`.
- Credentials are stored safely, and installing and updating are simple.

**SDKs**
- Each feels natural in its language, and has types where the language supports them.
- Retries, timeouts, pagination, and errors are handled for the caller.
- It's generated from the spec or tested against the real API, so it can't drift.
- Versions follow semantic versioning, and dependencies stay few.

**Don't flag:** API design polish for a private API only your own frontend uses. Consistent errors and permissions still matter there.

## innovation

Look for where AI or newer technology could make this feel slick. These are Ideas rather than defects, so never let them block shipping. Offer at most 3 to 5 good ones.

- Replace a form or setup step with smart defaults, inference, or import.
- Natural-language input, summaries, drafts, suggestions, or anomaly detection where they'd save real effort.
- Proactive help: notice what the user is trying to do and do the next step.
- New platform capabilities: passkeys, view transitions, on-device AI, MCP or agent access, real-time collaboration, native integrations.
- Automation of something users repeat by hand.

For each idea give the user benefit, a rough effort, and running cost. Check it against the `cost` lens: if a deterministic approach gets the same result, propose that instead. Skip ideas that are novelty without a user benefit.
