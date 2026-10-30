#!/usr/bin/env bash
# Links every skill in this repo into ~/.claude/skills. Safe to re-run.
# Never replaces a folder, a file, or a link pointing somewhere else.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target="$HOME/.claude/skills"
mkdir -p "$target"

skipped=0
for skill in "$repo"/skills/*/; do
  name=$(basename "$skill")
  source="${skill%/}"
  link="$target/$name"
  if [ -L "$link" ] && [ "$(readlink "$link")" != "$source" ]; then
    echo "skipped $name: already links to $(readlink "$link")"
    skipped=$((skipped + 1))
  elif [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "skipped $name: something else already exists at $link"
    skipped=$((skipped + 1))
  else
    ln -sfn "$source" "$link"
    echo "linked  $name"
  fi
done

if [ "$skipped" -gt 0 ]; then
  echo "$skipped skipped. Move those aside and run this again to use the versions in this repo."
  exit 1
fi
