# Persona starting points

These are prompts, not a checklist. Tailor each one to the product, using its real plan names, roles, and use cases. Drop any that don't fit, and split one when two people in it would want different things.

## Customers

| Persona | Cares about |
|---|---|
| Free plan customer | Real value before paying, fair limits, no dark patterns, a clear reason to upgrade |
| Paid plan customer | Getting what they paid for, no ads or nags, priority on speed and support |
| Small individual customer | Fast setup, low price, no need for a team or admin |
| Big corporate customer | SSO, roles, audit logs, invoices, security reviews, data residency, SLAs, bulk actions, scale |
| Customer with the main need | The product's main use case, from start to finish |
| Customer with a different need | A secondary or edge use case that's easy to break |
| Privacy-concerned customer | What's collected, who sees it, opt-outs, export, deletion, whether AI trains on it |
| Efficiency-concerned customer | Fewest clicks, keyboard shortcuts, bulk actions, speed, automation, APIs |
| Admin managing other users | Inviting, removing, roles, seeing who did what |
| Developer integrating through the API | Clear docs, stable contracts, test mode, useful errors |

Also make a persona for each role, plan, and account type the code defines.

## Situations

The same person in a particular moment often needs more than a different person does.

- First-time user who has never seen it
- Non-technical or low-confidence user
- Expert or power user
- User with a disability (screen reader, keyboard only, low vision)
- Mobile user on a slow connection
- Non-native English speaker or user in another region
- Budget-conscious user comparing competitors
- Returning user after a long gap or a redesign
- Skeptic looking for reasons not to trust it
- Customer whose trial expired or payment failed
- Customer who just hit a limit or an error
- Departing customer trying to cancel or leave with their data

## Team

These people run the product and support its users. Ask what each one looks for when they log in, and what they'd need to do their job without asking a developer.

| Persona | Looks for |
|---|---|
| CEO or owner | Health at a glance: growth, revenue, churn, what's on fire |
| Product manager | Feature usage, funnels, feedback, what to build next |
| Developer | Clear errors, logs, feature flags, a safe way to reproduce a customer's problem |
| QA tester | Test accounts for each plan and role, seeded data, predictable states, a way to reset them |
| Designer | Consistent components, every UI state reachable, real content lengths |
| Customer support agent | Finding a customer fast, seeing what they see, account history, safe fixes, canned answers |
| Account manager | An account's health, usage, renewal date, and what to raise with them next |
| Sales rep | A credible demo account, plan comparisons, trial status, lead details |
| Marketing | Landing pages, campaign results, SEO, what can be changed without a deploy |
| Finance or billing | Invoices, refunds, failed payments, tax, exports for accounting |
| Operations or on-call | Status, alerts, queues, safe manual overrides |
| Compliance or legal | Audit trails, consent records, data export and deletion requests |

Only include a team role the project could have. A solo side project may have one person wearing every hat, so one owner-operator persona can be enough.

## Projects that aren't apps

- **Library, CLI, or API:** developers adopting it, upgrading it, debugging it, and contributing to it, plus the maintainer.
- **Content, course, or documentation:** readers at different experience levels, plus editors.
- **Agency or client work:** the client, their customers, and whoever maintains it after handoff.
