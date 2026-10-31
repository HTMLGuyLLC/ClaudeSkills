# Group 5: Accessibility, simplicity, consistency, docs, UX

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

**How to check:** run axe or Lighthouse if the app can run, and use the keyboard yourself. Code review alone can't prove contrast or focus order, so mark those Not verified without a running app.

## simplicity

**Verbiage suits every reader level**
- Plain words, short sentences, no unexplained jargon. A beginner should understand it, and an expert shouldn't feel talked down to.
- Labels say what things do. Error messages, tooltips, and empty states guide the next step.

**Configuration is quick and easy, with more available**
- Works well on sensible defaults, with zero or minimal setup.
- Advanced options exist but stay out of the way until needed.
- Count the steps to first value and flag any that could go.
- Remove choices and settings that don't earn their place. Every option is a cost to the user.

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
- **Cross-browser:** works on the browsers the product supports, including Safari on iOS.
- **i18n:** strings not hardcoded if the product is translated, long-text and right-to-left layouts, and locale formats.
- **SEO and sharing (public pages):** titles, descriptions, canonical URLs, sitemaps, structured data, and Open Graph images.

**How to check:** run the app and take screenshots of each key page at the widths above, in both themes, then judge what you see. Look at the page before reading its code, so the code doesn't tell you what you're supposed to see. Attention, hierarchy, theme, and layout can't be proven from code, so mark them Not verified without a running app or screenshots. Give each finding the page, width, and theme where it shows up.
