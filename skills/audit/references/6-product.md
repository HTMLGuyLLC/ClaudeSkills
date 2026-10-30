# Group 6: Personas, plans, innovation

## personas

Walk through the changed experience as each person on the list, in their shoes and with their constraints. Ask what they'd notice, want, or get stuck on. This finds what code review misses.

**Choose the personas.** Use only the list in your brief, and don't invent your own. Pick by each persona's `Areas` and by what the change touches. Include team personas when it touches something they rely on, such as admin pages, support tools, reports, or seeded test accounts.

Use a representative 4 to 8 personas for an ordinary change, and all that fit for a release or full audit. Skip personas the change can't affect, with a reason.

**For each persona, report:** their goal, the path they took, what worked, and where they got stuck, were confused, or felt let down. Findings must point to actual behavior in code or copy. Don't invent user opinions or claim research that didn't happen. These are informed walkthroughs, not user testing.

**Spot gaps.** If the code shows a kind of user nobody on the list covers, such as a new role or plan, return it as a suggested persona with the evidence. A suggestion isn't a finding.

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
