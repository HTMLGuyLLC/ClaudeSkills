# Claude Skills

Custom Claude Code skills, kept here so they're tracked and can be restored on any machine.

| Skill | What it does |
|---|---|
| [`audit`](skills/audit/SKILL.md) | Audits changes for security, performance, resilience, accessibility, legal, consistency, personas, and more |
| [`loop-audit`](skills/loop-audit/SKILL.md) | Runs `audit`, fixes what it finds, and repeats until only rare low-priority edge cases remain |

## Set up a machine

```bash
git clone https://github.com/HTMLGuyLLC/ClaudeSkills.git ~/Web/ClaudeSkills
~/Web/ClaudeSkills/install.sh
```

`install.sh` links each skill into `~/.claude/skills/`, so edits here apply right away. Run it again after adding a skill. It skips any name that already exists there as a real folder, so nothing gets overwritten.

## Add a skill

1. Create `skills/<name>/SKILL.md`.
2. Run `./install.sh`.
3. Commit and push.
