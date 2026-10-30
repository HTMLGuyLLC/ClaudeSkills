# Claude Skills

Custom Claude Code skills, kept here so they're tracked and can be restored on any machine. A skill is a command you type in Claude Code, like `/audit`.

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

**Check what you're working on now:**

```text
/audit
```

**Check something specific:**

```text
/audit pr 123
```

```text
/audit last 3
```

```text
/audit src/checkout
```

```text
/audit all
```

**Check only one topic:**

```text
/audit security
```

```text
/audit personas
```

**Check how your pages look and work:**

```text
/audit ux
```

This checks what catches the eye, whether the main buttons push people toward the key actions, light and dark mode, and mobile at every screen size. It also covers layout, loading and error states, and first-time use. It needs a running app or screenshots to judge how things look.

**Check that what you promise is still true:**

```text
/audit legal
```

This compares your privacy policy and terms with what the product really does. It also checks every claim on your site and in your app, like "cancel anytime" or "99.9% uptime", and marks each one True, False, Stale, or Unproven. It always asks before rewording legal pages or claims, even with `--fix`.

**Check a group of topics:**

```text
/audit protect
```

The groups are `protect`, `reliability`, `observability`, `engineering`, `experience`, and `product`.

**Options:**

- `--quick` looks only for serious problems, and costs less.
- `--fix` also fixes the Critical, High, and Medium problems it finds, except legal pages and claims.

```text
/audit pr 123 --quick
```

The first time the `personas` check runs in a project, it uses `/personas` to work out who your users are. After that it reuses the saved list.

### `/loop-audit`

**What it does:** Runs `/audit`, fixes what it finds, and audits again, until only rare, minor issues are left. Anything that needs a human decision goes on a list for you. It doesn't commit unless you ask. This one can use a lot of tokens, and it tells you the worst case before it starts.

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
/personas debate what should be included in the bills page
```

```text
/personas debate how can we improve the homepage
```

```text
/personas debate would it be useful to add shared budgets
```

The personas each give their view alone, argue with each other, then vote on a proposal. You get a recommendation, or an honest "they couldn't agree". The result shows who still disagrees and what a person needs to decide. A full report goes in `.claude/debates/`.

**Debate options:**

- `--with` picks who debates, up to 7.
- `--quick` is cheaper, but one AI plays everyone, so the views aren't independent.

```text
/personas debate should we drop the free plan --with "Free plan customer, Owner, Support agent"
```

These debates are simulated by AI from your project's files. They help you think, but they aren't real user research. A debate never changes your code.

### `/release`

**What it does:** Ships your work from start to finish. It commits, opens a PR, waits for tests and reviews, fixes what comes back, merges, and runs your project's release process. If it gets stuck or stops partway, run it again and it picks up where it left off.

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

**What it does:** Improves plain code or rules, like a spam filter or a bill categorizer, by testing them against real examples. AI helps while you develop, but the finished logic has no AI in it, so it's cheap and predictable to run. It keeps a change only if the score really improves.

**Improve something:**

```text
/improve-deterministic the spam filter
```

**Stop at a score or a number of rounds (the default limit is 10 rounds):**

```text
/improve-deterministic the bill categorizer --target 95 --max 5
```

**Remove its test data when you're done:**

```text
/improve-deterministic cleanup spam-filter
```

Its data stays in a `.improve/` folder that git ignores. That folder may hold private data, and it asks before copying or deleting anything private.

### `/cleanup`

**What it does:** Reviews the git worktrees in every repo Claude has worked in. It removes the ones whose work is merged and that nothing is using, along with merged branches and dead worktree records. It shows you anything unfinished and asks first, and it never touches a worktree that a chat or process is using.

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
/cleanup ~/Web/my-app
```

**Do only the safe removals, and list the rest for later:**

```text
/cleanup --no-ask
```

Commits that only a detached worktree holds are saved to a `rescue/` branch before it's removed. If you remove unfinished work and keep it, the branch stays and uncommitted changes go to a stash. It never deletes remote branches or chat history. Full detection needs the Claude desktop app on a Mac, and it works from `git` alone elsewhere.

## Set up a machine

This repo is private, so sign in to GitHub first. `/release` and `/audit pr` also need `gh`.

```bash
brew install gh
```

```bash
gh auth login
```

```bash
gh auth setup-git
```

```bash
git clone https://github.com/HTMLGuyLLC/ClaudeSkills.git ~/Web/ClaudeSkills
```

```bash
~/Web/ClaudeSkills/install.sh
```

`install.sh` links each skill into `~/.claude/skills/`, so edits here apply right away. The live skills follow the checked-out branch, so keep this repo on `main`. Run it again after adding a skill. It never replaces a folder, a file, or a link that points somewhere else. It lists those and exits with an error so you can move them aside.

`/audit` uses more scanners if they're installed. None are required:

```bash
brew install gitleaks osv-scanner semgrep shellcheck
```

## Add a skill

1. Create `skills/<name>/SKILL.md`.
2. Run `./install.sh`.
3. Run `tests/run.sh`.
4. Commit and push.

To remove a skill, delete its folder here and its link in `~/.claude/skills/`.

## Tests

`tests/run.sh` checks the scripts offline, using a stub `gh`, temporary repos, and a temporary `HOME`. It needs only `git` and `jq`, and CI runs it on every PR.
