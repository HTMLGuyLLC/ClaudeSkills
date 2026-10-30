#!/usr/bin/env bash
# Lists what a project has already written about its personas. Changes nothing.
# Usage: find.sh
# Prints saved, last_reviewed, also_defined_in, any agents and note lines, then
# one file:line match per line. Run it anywhere inside the project.
set -uo pipefail

max_matches=${PERSONA_MAX_MATCHES:-100}
per_file=3
pattern='(^|[^a-z])personas?([^a-z]|$)|(user|customer|buyer) (type|role|segment)s?|target (user|audience|customer|market)s?|ideal customer|who (it|this)( i|.)s for|jobs[ -]to[ -]be[ -]done'

in_git=false
if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  in_git=true
  cd "$root" || exit 1
fi

saved=.claude/personas.md
if [ -f "$saved" ]; then
  echo "saved: yes"
  echo "last_reviewed: $(sed -n 's/^Last reviewed: *//p' "$saved" | head -n 1)"
  echo "also_defined_in: $(sed -n 's/^Also defined in: *//p' "$saved" | head -n 1)"
else
  echo "saved: no"
fi

for agent in .claude/agents/*.md; do
  [ -f "$agent" ] && echo "agent: $agent"
done

list_files() {
  if [ "$in_git" = true ]; then
    git ls-files -coz --exclude-standard
  else
    find . \( -name .git -o -name node_modules -o -name vendor -o -name dist -o -name build \) -prune \
      -o -type f -print0
  fi
}

shopt -s nocasematch
count=0
while IFS= read -r -d '' file; do
  file=${file#./}
  case "$file" in
    "$saved" | .claude/audits/* | .claude/debates/* | *changelog*) continue ;;
    *.md | *.mdx | *.markdown | *.txt | *.rst | *.adoc) ;;
    *) continue ;;
  esac
  [ -f "$file" ] || continue
  while IFS= read -r match; do
    if [ "$count" -ge "$max_matches" ]; then
      echo "note: stopped at $max_matches matches, so search further if the list looks incomplete"
      exit 0
    fi
    printf '%s\n' "$match" | cut -c1-160
    count=$((count + 1))
  done < <(grep -inIHE -m "$per_file" -- "$pattern" "$file")
done < <(list_files)
