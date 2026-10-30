#!/usr/bin/env bash
# Reserves a new report file for /personas debate and keeps reports out of git.
# Usage: debate-path.sh <topic>
# Prints the file's full path. Never reuses a name, so earlier debates survive.
set -euo pipefail

slug=$(printf '%s' "$*" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cs 'a-z0-9' '-' |
  sed 's/^-*//' | cut -c1-50 | sed 's/-*$//')
slug=${slug:-debate}

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
  exclude=$(git rev-parse --git-path info/exclude)
  mkdir -p "$(dirname "$exclude")"
  grep -qxF '.claude/debates/' "$exclude" 2>/dev/null || echo '.claude/debates/' >> "$exclude"
fi

mkdir -p .claude/debates
base=".claude/debates/$(date +%F)-$slug"
path="$base.md"
n=2
until (set -C; : > "$path") 2>/dev/null; do
  path="$base-$n.md"
  n=$((n + 1))
done
echo "$PWD/$path"
