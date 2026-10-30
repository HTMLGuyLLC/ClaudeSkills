# Group 1: Security and legal

## security

Standards: the current editions of the OWASP Top 10, OWASP API Security Top 10, OWASP Top 10 for LLM Applications (if the product uses AI), OWASP ASVS for depth, and PCI DSS. Confirm the current edition if a finding depends on one.

**Permissions, login, and sessions: extra attention**

Mistakes here tend to expose every account at once, so any change touching this code gets a line-by-line read of the full flow, not just the diff. Trace it from the request through to the data, and try to bypass it. When in doubt, rate a real weakness here one level higher than you would elsewhere.

- Permissions:
  - Every endpoint, query, background job, and file or export link checks authentication, role, and ownership on the server, on each request. The UI hiding a button proves nothing.
  - Deny by default. New routes and tables start closed.
  - Look for IDOR, tenant leaks, privilege escalation (a user changing their own role, or mass assignment of `role` or `isAdmin`), and admin routes guarded only by the UI.
  - Removing a role, a seat, or a plan takes effect right away, including on cached permissions and existing sessions.
  - Impersonation and admin actions are limited and written to an audit log.
- Login and signup:
  - Rate limits, lockout, or backoff against guessing and credential stuffing.
  - Responses don't reveal whether an account exists, on login, signup, or password reset.
  - Password reset and magic-link tokens are random, single-use, short-lived, and invalidated once used.
  - OAuth and SSO check `state`, PKCE, redirect URLs, and verified email before linking accounts.
  - MFA is available, and required for sensitive actions where it fits. Recovery can't be used to skip it.
- Sessions:
  - Cookie flags are set (`HttpOnly`, `Secure`, `SameSite`), with session ids that are random and rotated at login and on privilege change (session fixation).
  - Idle and absolute timeouts fit the risk. Logout really ends the session on the server.
  - Changing a password or a role revokes other sessions.
  - JWTs: signature and algorithm verified, expiry short, revocation possible, nothing sensitive in the payload, and not kept in `localStorage`.
- Sensitive changes (email, password, payout details, API keys) ask the user to re-authenticate.

**Secure credential handling**

- Passwords: hashed with Argon2id, scrypt, or bcrypt with a unique salt. Never stored in plain text, reversible, or with a fast hash like MD5 or SHA-256.
- Secrets live in a secret manager or env vars, never in code, git history, client bundles, logs, error reports, URLs, or example files. Env vars exposed to the browser (`NEXT_PUBLIC_`, `VITE_`) must hold nothing private.
- Each API key and token has the narrowest scope that works, can be rotated without downtime, and has an expiry where the provider allows one. Keep separate credentials per environment.
- Customer-supplied credentials and third-party tokens (OAuth tokens, API keys) are encrypted at rest and never shown back in full.
- Keys issued to customers are stored as hashes, shown once, and can be revoked.
- Compare secrets in constant time. Credentials never travel over plain HTTP or in query strings.
- A secret that was ever committed or logged counts as leaked: rotate it, since deleting the line isn't enough.

**OWASP**
- Injection: SQL, NoSQL, command, template, path traversal, and XSS, including `dangerouslySetInnerHTML` and unsanitized markdown.
- Cryptography: current algorithms, no home-grown crypto, encryption in transit and at rest, safe randomness for tokens.
- Misconfiguration: CORS, CSRF, security headers and CSP, debug modes, verbose errors, default credentials, public buckets.
- SSRF, unsafe deserialization, open redirects, unsafe file uploads, webhook signature checks.
- Row-level security: on Supabase or similar, every table has correct policies and explicit grants, and privileged keys never reach the client.

**PCI**
- Find where card data flows. Card numbers or CVVs in logs, databases, analytics, URLs, or error reports are Critical.
- Prefer hosted fields or checkout (Stripe Elements or Checkout, etc.), which keep the product out of most PCI scope. Confirm this is really how it works.
- If the product never touches card data, mark PCI N/A and name the payment path.

**Dependencies are on latest versions**
- Use scanner output. Without it, query the registry directly. Don't rely on memory.
- Known vulnerabilities reachable from this code: High or Critical.
- Behind latest stable: Low for minor versions, Medium for a major version or an end-of-life runtime or framework.
- Check that lockfiles are committed, packages aren't abandoned, and newly added packages are real and aren't typosquats.
- A version pinned on purpose with a stated reason is fine.

**Abuse**
- Rate limits on AI calls, email or SMS sending, and expensive endpoints.
- Abuse of free tiers, bulk signups, unbounded uploads, and spam through user content.
- AI features: prompt injection from user or fetched content, output used without validation, tools given too much access, one customer's data reaching another through context.

**Don't flag:** theoretical attacks with no path from an attacker to the code, or hardening that's irrelevant to the threat (CSRF on a stateless token API, for example).

## legal

Flag risks and obligations for a person to confirm. You aren't a lawyer, but say plainly what's missing and why it matters, then recommend counsel for Critical items only.

This lens has to read beyond the diff, because a code change can break a promise made on a page the diff never touches.

**Terms and privacy exist**
- Terms of service and privacy policy exist and are linked where users sign up and pay.
- Find them in the repo, then on the live site if the project gives its URL. If they can't be read, mark this part Not verified, never Pass.

**Terms and privacy are still accurate**

On a diff, check every statement the change could affect. On `all`, go through each document statement by statement. Work in both directions: what the documents say against the code, and what the code does against the documents. A new data type, vendor, cookie, or AI provider usually means the privacy policy is stale.

- **Data collected:** every field, upload, log, and analytics event is covered, and nothing listed has stopped being true.
- **Why and with whom:** each purpose is real. Every subprocessor and data transfer is disclosed, checked against dependencies, env vars, scripts, tags, and server calls. AI providers: state whether customer data is sent and whether it's used for training.
- **Cookies and tracking:** the list matches what the app actually sets and loads.
- **Retention and deletion:** stated periods are enforced by real code, and "delete" really removes the data, including from vendors and backups if promised.
- **User rights:** every export, correction, opt-out, or unsubscribe promised actually works.
- **Security statements:** encryption, access limits, and data location match the setup.
- **Commercial terms:** prices, trials, refunds, cancellation, auto-renewal, limits, and uptime promises match the billing config and product. Age limits and easy cancellation are in place where required.
- **Details:** company name, contact address, governing law, linked pages, and the last-updated date are all current.

**Every claim is true**

Search the whole product for claims, not just the scope: UI copy, marketing pages, pricing, emails, onboarding, help content, README, metadata, and store listings. List each claim, then trace it to the code or data that proves it.

- **Features:** "works offline", "integrates with X", "real-time", "unlimited", "automatic".
- **Numbers:** customer counts, uptime, speed, savings, accuracy, and "saves 3 hours".
- **Security and compliance:** "secure", "encrypted", "SOC 2", "HIPAA compliant", "GDPR ready".
- **Privacy:** "we never sell your data", "stays on your device", "no tracking".
- **Pricing:** "free forever", "no card required", "cancel anytime", "money-back guarantee".
- **Comparison and proof:** "#1", "fastest", competitor tables, testimonials, customer logos, awards, and fake urgency.

Mark each claim True, False, Stale, or Unproven. A false or stale claim is at least High, and Critical if it's about data, security, or money. If the repo can't prove a claim, such as a customer count or a testimonial, list it for a person to confirm. Never assume it's true. Skip obvious opinion and puffery, such as "beautiful" or "delightful".

A claim can be fixed by changing the product or the words. Say which you recommend. Give every checked claim a row in the report's Claims checked table, so the reader can see what was covered.

**Disclaimers**
- Add one only where the law or a real risk needs it: financial, medical, or legal information, AI-generated output people may rely on, health or safety, earnings claims.
- A disclaimer that draws attention to a weakness without reducing real risk hurts the product's image. Flag unnecessary ones for removal or quieter placement (terms instead of the main UI) as well as flagging missing ones.

**Region-specific features**
- GDPR/UK GDPR: lawful basis, consent before non-essential cookies, data export and deletion, DPA for business customers.
- US state privacy laws, including CCPA/CPRA: "Do Not Sell or Share" and opt-outs where they apply.
- EU AI Act and similar: tell users when they're interacting with AI or seeing AI-generated content where required.
- Accessibility law (ADA, European Accessibility Act), COPPA, CAN-SPAM and TCPA for messaging, tax and invoicing on sales, sector rules such as HIPAA, GLBA, or FERPA.
- Only raise rules that plausibly apply to where this product is sold and who uses it.

**Licenses and IP**
- Dependency licenses compatible with distribution (copyleft in closed-source products), required attribution, rights to fonts, images, and scraped data, and terms of third-party APIs the product uses.
