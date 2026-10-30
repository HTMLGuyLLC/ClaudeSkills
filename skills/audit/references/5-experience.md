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

## ux

- **States:** loading, empty, error, success, partial, offline, and long-content cases all designed.
- **Forms and flows:** clear next action, undo or confirmation for destructive actions, no lost work, and feedback within 100ms.
- **Responsive:** phone, tablet, desktop, and touch, with no horizontal scroll.
- **Cross-browser:** works on the browsers the product supports.
- **i18n:** strings not hardcoded if the product is translated, long-text and right-to-left layouts, and locale formats.
- **SEO and sharing (public pages):** titles, descriptions, canonical URLs, sitemaps, structured data, and Open Graph images.
