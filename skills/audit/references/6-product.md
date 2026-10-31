# Group 6: Personas, admin, plans, innovation

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

## innovation

Look for where AI or newer technology could make this feel slick. These are Ideas rather than defects, so never let them block shipping. Offer at most 3 to 5 good ones.

- Replace a form or setup step with smart defaults, inference, or import.
- Natural-language input, summaries, drafts, suggestions, or anomaly detection where they'd save real effort.
- Proactive help: notice what the user is trying to do and do the next step.
- New platform capabilities: passkeys, view transitions, on-device AI, MCP or agent access, real-time collaboration, native integrations.
- Automation of something users repeat by hand.

For each idea give the user benefit, a rough effort, and running cost. Check it against the `cost` lens: if a deterministic approach gets the same result, propose that instead. Skip ideas that are novelty without a user benefit.
