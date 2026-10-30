# Claude Skills

Custom Claude Code skills, kept here so they're tracked and can be restored on any machine.

| Skill | What it does |
|---|---|
| [`audit`](skills/audit/SKILL.md) | Audits changes for security, performance, resilience, accessibility, legal, consistency, personas, and more. Run part of it with a lens or bundle, like `/audit personas` or `/audit protect` |
| [`loop-audit`](skills/loop-audit/SKILL.md) | Runs `audit`, fixes what it finds, and repeats until only rare low-priority edge cases remain |
| [`personas`](skills/personas/SKILL.md) | Finds or creates a project's customer, situation, and team personas, checks them for gaps, and saves the approved list to `.claude/personas.md`. `audit` uses that list and runs this the first time a project has none. `/personas debate <question>` makes them argue a product decision and reports a consensus or an honest split |
| [`release`](skills/release/SKILL.md) | Commits, opens a PR, waits for CI and reviews, fixes what comes back, merges, and runs the project's release process |
| [`improve-deterministic`](skills/improve-deterministic/SKILL.md) | Uses AI to test and refine deterministic logic against real data, so the app doesn't need AI at runtime. Keeps test data and your corrections in a git-ignored `.improve/` folder in each project |

## Set up a machine

This repo is private, so sign in to GitHub first. `/release` and `/audit pr` also need `gh`.

```bash
brew install gh
gh auth login
gh auth setup-git
git clone https://github.com/HTMLGuyLLC/ClaudeSkills.git ~/Web/ClaudeSkills
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
