# Group 5: Accessibility, compatibility, simplicity, consistency, docs, UX, SEO

## a11y

Target WCAG 2.2 AA at minimum. Take AAA when it's low-hanging fruit.

**AA**
- Keyboard: everything works without a mouse, focus is visible and in a logical order, no traps, and modals manage focus.
- Screen readers: semantic HTML first, ARIA only when needed, labels on inputs and icon buttons, useful alt text, and live regions for dynamic updates.
- Contrast: 4.5:1 for text, 3:1 for large text and UI parts. Check both light and dark themes.
- Forms: visible labels, errors linked to fields and not shown by color alone.
- Target size at least 24×24px, reflow at 320px, text resizable to 200%, and heading order and landmarks correct.
- Respect `prefers-reduced-motion`, and pause controls on moving content.
- Video captions and audio transcripts. `lang` set, page titles unique.

**AAA when cheap:** 7:1 contrast where the palette allows it, 44×44px targets, plain-language copy, no time limits, and no needless animation. Report these as Low or Idea, never as blockers.

Attention span and quick reading are covered by `ux`.

**How to check:** run axe or Lighthouse if the app can run, and use the keyboard yourself. Code review alone can't prove contrast or focus order, so mark those Not verified without a running app.

## compatibility

The project needs a written target for what it supports, and all code has to work on that target. This covers where the product runs. Keeping old APIs and saved data working is covered by `delivery`, and screen sizes by `ux`.

**A target is set**

Look for it in the `## Compatibility` section of `.claude/audit.md`, `browserslist`, the build and TypeScript `target`, `engines`, `.nvmrc`, `requires-python`, the iOS deployment target, Android `minSdk`, and the docs. Report a finding if it's missing, if these disagree, or if a tool that could read the target doesn't.

The target states whatever applies:
- **Browsers:** which ones and how far back, including Safari on iOS, in-app webviews, and email clients for HTML email.
- **Devices and operating systems:** minimum iOS, Android, Windows, and macOS versions, chip architectures, and touch or mouse.
- **Runtimes and data stores:** language, database, and service versions, the same across development, CI, and production.
- **Scripts and CLIs:** shells, operating systems, and differences such as BSD and GNU tool flags.

Base a proposed target on real usage data if the project has it, or otherwise on who its customers are. The target should also match any public claim, such as "works on every browser".

**All code complies**

Check each feature against the target using current data from MDN, Can I Use, or Baseline, not memory. Use `eslint-plugin-compat`, Stylelint compatibility rules, or similar if the project has them. On a diff, check what the change adds. On `all`, check the code and its dependencies.

- **JavaScript:** build tools convert new syntax, but not new APIs, so APIs like `Object.groupBy` or `Array.prototype.toSorted` need a polyfill or a check.
- **CSS:** newer features like `:has()`, container queries, nesting, `dvh`, and `oklch` need support or a fallback.
- **Web platform:** `popover`, view transitions, the Clipboard API, service workers, and web push work differently across browsers, and iOS adds its own limits.
- **Native:** newer APIs sit behind availability checks, such as `#available` or `SDK_INT`.
- **Dependencies:** each package supports the target, including packages published as untranspiled modern code.
- **Behavior differences:** date parsing, autoplay, file inputs, storage limits, and fonts can differ even where a feature exists.

**Failing well**
- Detect features rather than checking the browser's name.
- Where a feature isn't essential, the page still works without it.
- A browser below the target gets a clear message, not a blank page.

**Not too far back:** a target older than the users needs costs real money. Flag polyfills and workarounds for versions outside the target, and targets that users don't justify.

**Severity:** High when a main flow, such as signup or checkout, breaks on a supported target. Medium when a feature fails there. Low when a fallback works but looks worse.

**How to check:** compatibility data shows what should work. To prove it, run the app on the oldest targets, using real devices, a device cloud, or Playwright's WebKit. Mark anything that wasn't run Not verified.

**Don't flag:** new features with a working fallback, browsers outside the target, or a small internal tool with a short target that everyone uses.

## simplicity

**Verbiage suits every reader level**
- Plain words, short sentences, no unexplained jargon. A beginner should understand it, and an expert shouldn't feel talked down to.
- Labels say what things do. Error messages, tooltips, and empty states guide the next step.

**Configuration is quick and easy, with more available**
- Works well on sensible defaults, with zero or minimal setup.
- Advanced options exist but stay out of the way until needed.
- Count the steps to first value and flag any that could go.
- Remove choices and settings that don't earn their place. Every option is a cost to the user.

**Local setup is clone and run**

A new developer or AI agent should get from a fresh clone to a running app with as few commands as possible. This is the target:

```bash
git clone <repo>
make setup
make run:dev
```

Or, where a build step matters: `make setup`, `make build`, `make run`.

- **Setup does the work:** it installs dependencies, creates local config from the example, starts what the app needs, such as Docker images, then runs migrations and seeds. `migrations` checks those steps in depth.
- **Setup is idempotent in most cases:** running it again skips or safely repeats finished work, with no errors, duplicates, or lost local data. That also makes it the easy way to catch up after pulling new changes. Anything destructive, like wiping a database, belongs in a separate reset command.
- **Usable right away:** seed data includes test accounts and realistic content, and any manual step, such as adding an API key, is clearly explained.
- **Same commands across stacks:** a task runner keeps the names the same, instead of `npm run dev` here and `symfony serve` there. `make` works well for this, but it isn't required. One clear, documented command per job is what counts.
- **Prerequisites are clear:** required tools and versions are listed and checked, ideally by setup itself.
- **The docs are true:** the README's first steps match what really works, and CI uses the same commands so they stay working.

## consistency

This lens has to search the whole repo, because inconsistency lives outside the diff.

**Verbiage**
- For each changed or new user-facing term, search code, UI, docs, emails, marketing, and help content for the old and related wording. A verbiage update must reach all of them.
- One concept, one name. Public labels and code names should match where possible.
- Menu items match page titles, and buttons match the action they lead to.
- Tone, capitalization, and date, number, and currency formats match.

**Naming:** conventions stay the same across variables, functions, files, routes, database columns, events, and public labels.

**Design:** tokens rather than hardcoded colors and spacing. Same patterns for the same interactions. Follow `DESIGN.md` or the design system if there is one.

**Components:** if a component exists for this job, use it everywhere. Search before accepting anything new, and flag near-duplicates.

**Architecture:** if several places do the same thing, they do it the same way: same data access, error handling, validation, and auth patterns.

**Ideals:** decisions match what the product says it stands for, such as a privacy promise, a simplicity claim, or tone of voice.

**Sibling fixes:** a bug fixed in one place should be fixed in the copies too.

## docs

Search for everything the change makes stale, then check each one.

- README, setup steps, and screenshots.
- Other markdown: `docs/`, `CONTRIBUTING`, `CHANGELOG`, ADRs, and `CLAUDE.md` or `AGENTS.md`.
- Help center and support content, in-app help, tooltips, and onboarding.
- API docs, SDK examples, and env var references.
- Blog, marketing pages, pricing and feature lists, and emails.

If these live outside the repo, list what needs updating and mark it Not verified. A shipped feature with no customer-facing announcement is worth an Idea-level note.

**Changelogs and What's new**

Each public changelog, What's new panel, or release note has an audience. Work out who can see it, then check every entry from that reader's side.

- **Right audience:** an entry appears only where the people reading it are affected. Marketing site updates and admin panel changes don't belong in a changelog that normal customers see. Admin changes go somewhere only staff can see, and changes limited to one plan or role show only to those users where the changelog can target them.
- **Something they can see or experience:** a new feature, a visible change, a fixed problem they could have hit, or a real change in speed or reliability. Refactors, moved files, renamed functions, dependency bumps, test changes, and internal tooling stay out.
- **Described as the result:** behind-the-scenes work that users really feel is written as what they notice, like "Reports load twice as fast", not how it was done.
- **Actually available:** nothing unreleased, reverted, or hidden behind a flag for this audience. An entry doesn't mention anything that never reached them.
- **Plain and safe:** no internal names, ticket numbers, or commit hashes, and no security details that help an attacker. Say what to do if users must act.
- **Security fixes:** routine patches stay out, because readers can't see them and the details can help attackers. List one only if it was serious, users were confirmed affected, or users must act, such as by changing a password or rotating a key. Say what users need to know, not how the flaw worked. A changelog never replaces a notice the law or a contract requires, so flag any possible notice for a person to decide.
- **Generated changelogs:** if entries come from commits or PR titles, flag the process as well as the entries, so the same leak doesn't return.

**Don't flag:** a developer changelog whose readers use the code or API, such as a library's `CHANGELOG.md`. Internal changes that affect those readers belong there, and so do security fixes, because they need to know which versions to upgrade.

## ux

**Attention and eye flow**
- Squint test: name the first, second, and third things the eye lands on. They should be the most important things on the page, in that order.
- One clear focal point per view. Flag competing elements of equal weight, and decoration that outshouts content.
- Size, color, contrast, spacing, and motion lead the eye along a path that ends at the next action.
- Accent color is saved for what matters. If everything stands out, nothing does.
- The main message and action are visible without scrolling, and a first-time visitor can say what the page is for within 5 seconds.
- Anything that moves or pops up has to be worth the interruption.

**Attention span**

Content should be quick to take in, including for people with ADHD and anyone busy or distracted. This helps everyone, and it applies to marketing pages, in-app text, emails, and help content.

- **Skim test:** reading only the headings, bold text, and buttons still gives the main point and the next step.
- **Key point first:** each page and section leads with what matters most, before any background.
- **Small pieces:** short paragraphs, one idea per block, lists where they're clearer, and no walls of text.
- **Short by default:** cut anything that doesn't help. Extra detail sits behind a link or expandable section.
- **Quick tasks:** long forms and flows are split into small steps, with visible progress and a clear next action.
- **Few distractions:** no autoplay, rotating carousels, or stacked pop-ups competing with the task. A video has a text summary.
- **Easy to resume:** after an interruption, people can pick up where they left off without losing their work.

**Emotion and feel**

Name the feeling this product should create, using its brand, `DESIGN.md`, and audience, such as calm and safe for finance or playful for a game. Then judge whether each page creates that feeling. Before reading anything, write down three words for your first impression.

- **Color:** the palette creates the right mood. Blues often feel calm and trustworthy, reds urgent or alarming, greens positive, warm colors energetic, and muted tones quiet. Judge meaning against the audience and culture, because it varies. Too much red can make a calm task feel stressful, and color shouldn't contradict meaning, such as a red button for a positive action.
- **Layout and space:** generous space tends to feel calm and premium, and dense layouts feel busy or urgent, though experts may want that density. Symmetry feels stable, asymmetry feels energetic, and cramped layouts feel stressful.
- **Type:** the typefaces, weight, and size suit the mood, such as traditional, modern, or friendly.
- **Imagery and icons:** real photos, illustrations, and icon style fit the audience, and nothing feels generic or out of place.
- **Motion:** speed and easing match the mood, from soft and calm to quick and confident.
- **Words:** tone fits the moment. Errors stay calm and never blame the user, and successes feel earned.
- **Key moments:** check how people feel at first impression, while waiting, on an error, at payment, on bad news, and when leaving. Payment and privacy moments should reassure, and failed payments or cancellations should support rather than punish.
- **Trust:** the design looks credible enough for what it asks of people, especially money or personal data.

A finding here names the element, the feeling it creates, the feeling the product wants, and why that matters. Personal taste isn't a finding.

**Usability**
- **Status:** people can always tell what's happening.
- **Familiar:** it uses the users' own words, and standard patterns they already know.
- **Control:** people can cancel, go back, and undo.
- **Preventing mistakes:** good constraints and defaults stop errors before they happen.
- **Recognition over memory:** options stay visible, so people don't have to remember them.
- **Efficiency:** frequent users get shortcuts, and fewer choices lead to quicker decisions.
- **Help:** it's there at the moment it's needed.

**Navigation and flows**
- Navigation follows how users think, not how the company or code is organized, and labels are clear.
- Count the steps for each top task, then remove any that aren't needed. No flow ends in a dead end.
- Search works and copes with typos, where the product needs it.
- Forms ask for as little as possible, in a logical order, with autofill, smart defaults, and errors shown as people go.

**Calls to action**
- Each page or screen has one primary action, and it's obvious which one. Secondary and tertiary actions look clearly quieter.
- The hierarchy matches the business goal: the most valuable action gets the most weight, and key actions are pushed rather than buried.
- Labels say what happens next, as in "Start free trial" rather than "Submit" or "Click here".
- Long pages repeat the CTA at natural decision points, and the same action keeps the same label and style everywhere.
- Friction near the CTA is low: few fields, no surprise sign-up walls, and the price or commitment is clear before the click.
- Reassurance sits close to the decision, such as "no card required", proof, or guarantees, but only if it's true.
- Destructive actions are never styled as the primary action.
- No dark patterns: fake urgency, guilt-trip decline buttons, hidden cancel paths, or pre-ticked upsells.

**Hierarchy and layout**
- Type scale, weight, and spacing show what's related and what matters. Pages can be scanned through headings and short blocks.
- Alignment and spacing follow a consistent rhythm, and line length stays readable.
- Cognitive load is low: few choices at once, sensible grouping, and detail revealed when it's needed.
- Users always know where they are, how to get back, and what to do next. Page state survives refresh and deep links.

**Visual craft**
- **Color:** a small, harmonious palette where each color has a clear role.
- **Type:** few typefaces, a clear scale, and comfortable line height.
- **Grouping:** related things sit together and look alike, and white space separates what's different.
- **Imagery:** images are sharp, on brand, and in one style, and icons come from one set.
- **Polish:** corners, shadows, borders, and alignment are consistent, and nothing looks like an unstyled default.
- **Delight:** small touches reward people where they fit, without slowing them down.

**Light and dark mode**
- Both themes are designed, not inverted. Each has its own hierarchy, and the focal point and CTA stand out equally in both.
- Follows the system preference, lets the user override it, remembers the choice, and doesn't flash the wrong theme on load.
- Check what's usually missed: logos, images, icons, charts, shadows, borders, status colors, focus rings, native controls and scrollbars (`color-scheme`), third-party embeds, emails, and PDFs.
- No hardcoded colors that bypass the theme tokens. Contrast is covered by `a11y`.
- If only one theme exists, report dark mode as an Idea, not a defect.

**Mobile and screen sizes**
- Check 320, 375, 430, 768, 1024, 1440, and 1920+ wide, plus phone landscape. Also check sizes between breakpoints, where layouts tend to break.
- No horizontal scroll, clipped text, or overlapping elements. Tables, code blocks, and long words have a mobile plan.
- Mobile gets a designed layout, not a shrunken desktop one. The priority order still works when columns stack, and the primary CTA stays easy to reach.
- Primary actions sit within thumb reach, and targets aren't crowded.
- Nothing depends on hover. Long-press, swipe, and drag have visible alternatives.
- Forms use the right `inputmode`, `autocomplete`, and `type`. Input text is at least 16px so iOS doesn't zoom, and the on-screen keyboard doesn't cover the field or submit button.
- Sticky headers, banners, and cookie bars don't eat the small screen. Safe areas and notches are respected, and `100dvh` is used where `100vh` breaks.
- Modals, menus, and date pickers work on a phone. Images use the right sizes so phones don't download desktop assets.
- Large screens use the space well, with a sensible max width rather than stretched lines.

**States and feedback**
- Loading, empty, error, success, partial, offline, and long-content cases are all designed. Empty states lead to the next action.
- Controls show hover, focus, pressed, disabled, and selected states.
- Forms and flows have a clear next action, undo or confirmation for destructive actions, no lost work, and feedback within 100ms.
- No layout shift as content loads. How fast waits feel is covered by `performance`.
- Motion explains what changed, and stays short.

**Reach**
- **First run:** a new user reaches first value quickly, with guidance that doesn't block them.
- **Cross-browser:** covered by `compatibility`.

**Translation and locale** (if the product is translated, or has users in other countries)
- Text isn't hardcoded, and plurals and variables go through the translation library rather than joined strings.
- Dates, times, numbers, and currencies follow the user's locale, and time zones are clear.
- Layouts survive longer text and right-to-left languages.
- Emails, errors, PDFs, and legal pages are covered too, with a sensible fallback language.
- The language can be chosen and is remembered, rather than being guessed from location alone.

**SEO and sharing:** covered by `seo`.

**How to check:** run the app and take screenshots of each key page at the widths above, in both themes, then judge what you see. Look at the page before reading its code, so the code doesn't tell you what you're supposed to see. Attention, emotion, hierarchy, theme, and layout can't be proven from code, so mark them Not verified without a running app or screenshots. Give each finding the page, width, and theme where it shows up.

## seo

Mark this N/A if the product has no public pages. This lens asks whether search engines and AI assistants can find your pages, understand them, and recommend or cite them. Speed is measured by `performance`, and it matters here too.

**They can find and read it**
- Important content is in the HTML the server sends. Many AI crawlers don't run JavaScript, so a page that depends on it can look empty to them.
- `robots.txt`, the sitemap, and canonical URLs are correct, with no accidental `noindex`. Staging stays out of search.
- URLs are readable, moved pages redirect, and missing pages return a real 404.
- Internal links reach every important page.

**AI crawlers are a decision**
- `robots.txt` deliberately allows or blocks AI crawlers. Many companies run separate crawlers for training, for search, and for fetching pages a user asks about, so a site can block one and allow another. Check current crawler names.
- A blanket block can hide the site from AI answers. Bot protection or a CDN rule can do the same without anyone noticing, so check for that too.

**They can understand it**
- Each page has its own title, description, and one main heading, with headings in a clear order.
- Structured data is valid and matches what's on the page.
- Images have useful alt text, and shared links show a good preview with an Open Graph image.
- Translated pages use `hreflang`.

**The content is worth citing**
- Each important page answers a real question, with no thin pages or duplicates competing for the same search.
- Pages lead with a direct answer, in clear statements that make sense when quoted alone, backed by specific facts, dates, and sources.
- Prices, features, and limits are in plain text, not locked in images or behind a login.
- The same facts match across the site, docs, and listings, so AI tools don't repeat conflicting answers.
- Trust signals are clear: who wrote it, when it was last updated, and who runs the company.

**Measured**
- Search Console or similar is set up, and analytics can show traffic from search and AI tools.
- Someone periodically checks how AI assistants describe the product, and whether what they say is true.

**Fair play:** keyword stuffing, hidden text, showing crawlers different content, fake reviews, mass low-value pages, and text meant to manipulate AI tools are findings, even when they might work for a while.

**How to check:** fetch the raw HTML with JavaScript off and read what's really there. Use the SEO score from Lighthouse, and a rich results test for structured data. Rankings and AI citations can't be proven from code, so mark them Not verified.

**Severity:** High when a mistake hides the whole site or a key section. Medium for an important page that can't be read or is missing its basics. Low or an Idea for content improvements.

**Don't flag:** logged-in pages, or `llms.txt`, which is optional at most unless the project chooses to use it. Confirm current guidance before calling any AI optimization technique necessary, because this area changes quickly.
