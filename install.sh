#!/usr/bin/env bash
# Links every skill in this repo into ~/.claude/skills. Safe to re-run.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target="$HOME/.claude/skills"
mkdir -p "$target"

for skill in "$repo"/skills/*/; do
  name=$(basename "$skill")
  link="$target/$name"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "skipped $name: a real folder already exists at $link"
    continue
  fi
  ln -sfn "${skill%/}" "$link"
  echo "linked  $name"
done
