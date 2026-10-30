# Group 6: Personas, plans, innovation

## personas

Walk through the changed experience as each customer type, in their shoes and with their constraints. Ask what they'd notice, want, or get stuck on. This finds what code review misses.

**Choose the personas.** Use `.claude/audit.md` if it lists them. Otherwise derive them from the pricing page, plan gates in code, README, and marketing copy, and tailor these starting points to the product:

| Persona | Cares about |
|---|---|
| Free plan customer | Real value before paying, fair limits, no dark patterns, a clear reason to upgrade |
| Pro plan customer | Getting what they paid for, no ads or nags, priority on speed and support |
| Small individual customer | Fast setup, low price, no need for a team or admin |
| Big corporate customer | SSO, roles, audit logs, invoices, security reviews, data residency, SLAs, bulk actions, scale |
| Customer with a specific need (X) | The product's main use case, from start to finish |
| Customer with a different need (Y) | A secondary or edge use case the change could break |
| Privacy-concerned customer | What's collected, who sees it, opt-outs, export, deletion, whether AI trains on it |
| Efficiency-concerned customer | Fewest clicks, keyboard shortcuts, bulk actions, speed, automation, APIs |

Also add any that fit the product:
- First-time user who has never seen it
- Non-technical or low-confidence user
- Expert or power user
- User with a disability (screen reader, keyboard only, low vision)
- Mobile user on a slow connection
- Non-native English speaker or user in another region
- Budget-conscious user comparing competitors
- Returning user affected by what changed
- Admin managing other users
- Developer integrating through the API
- Support agent helping a customer
- Skeptic looking for reasons not to trust it
- Departing customer trying to cancel or leave with their data

Use a representative 4 to 8 personas for an ordinary change, and all that fit for a release or full audit. Skip personas the change can't affect, with a reason.

**For each persona, report:** their goal, the path they took, what worked, and where they got stuck, were confused, or felt let down. Findings must point to actual behavior in code or copy. Don't invent user opinions or claim research that didn't happen. These are informed walkthroughs, not user testing.

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
