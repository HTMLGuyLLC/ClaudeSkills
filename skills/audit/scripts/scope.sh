#!/usr/bin/env bash
# Works out what /audit should look at.
# Usage: scope.sh [auto|uncommitted|branch|pr [n]|last [n]|all|<a..b>|<path>...]
# Prints mode, label, diff_cmd, count, then one changed file per line.
set -uo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not a git repository; pass the paths to audit directly" >&2
  exit 1
fi
cd "$(git rev-parse --show-toplevel)" || exit 1

base_branch() {
  local ref
  ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null) && { echo "${ref#refs/remotes/origin/}"; return; }
  for ref in main master; do
    git show-ref --verify --quiet "refs/heads/$ref" && { echo "$ref"; return; }
  done
  echo main
}

base_ref() {
  local base; base=$(base_branch)
  if git show-ref --verify --quiet "refs/remotes/origin/$base"; then echo "origin/$base"; else echo "$base"; fi
}

is_dirty() { [ -n "$(git status --porcelain)" ]; }

ahead_count() {
  local base; base=$(base_ref)
  git show-ref --quiet "$base" || git rev-parse --verify --quiet "$base" >/dev/null || { echo 0; return; }
  git rev-list --count "$base..HEAD" 2>/dev/null || echo 0
}

latest_pr() {
  command -v gh >/dev/null 2>&1 || return 1
  gh pr list --state all --limit 1 --json number --jq '.[0].number // empty' 2>/dev/null
}

emit() { # mode label diff_cmd, then files on stdin
  local files count
  files=$(sort -u | sed '/^$/d')
  count=$(printf '%s' "$files" | grep -c . || true)
  echo "mode: $1"
  echo "label: $2"
  echo "diff_cmd: $3"
  [ -n "${also_ahead:-}" ] && [ "$also_ahead" != 0 ] && echo "also_ahead: $also_ahead commits not included"
  echo "count: $count"
  echo "files:"
  printf '%s\n' "$files"
}

scope_uncommitted() {
  also_ahead=$(ahead_count)
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard; } |
    emit uncommitted uncommitted "git diff HEAD (plus any untracked files listed)"
}

scope_branch() {
  local base; base=$(base_ref)
  git diff --name-only "$base...HEAD" | emit branch "branch-$(git branch --show-current | tr '/' '-')" "git diff $base...HEAD"
}

scope_pr() {
  local number=${1:-}
  command -v gh >/dev/null 2>&1 || { echo "error: gh is needed to audit a PR" >&2; exit 1; }
  [ -n "$number" ] || number=$(latest_pr)
  [ -n "$number" ] || { echo "error: no PRs found" >&2; exit 1; }
  gh pr diff "$number" --name-only | emit pr "pr-$number" "gh pr diff $number"
}

scope_last() {
  local n=${1:-1}
  git diff --name-only "HEAD~$n..HEAD" | emit commits "last-$n-commits" "git diff HEAD~$n..HEAD"
}

mode=${1:-auto}
case "$mode" in
  auto)
    if is_dirty; then scope_uncommitted
    elif [ "$(ahead_count)" -gt 0 ]; then scope_branch
    elif [ -n "$(latest_pr)" ]; then scope_pr
    else scope_last 1
    fi ;;
  uncommitted) scope_uncommitted ;;
  branch) scope_branch ;;
  pr) scope_pr "${2:-}" ;;
  last) scope_last "${2:-1}" ;;
  all) git ls-files | emit all full-repo "none; read the files directly" ;;
  *..*) git diff --name-only "$mode" | emit range "range-$(printf '%s' "$mode" | tr -c 'A-Za-z0-9._-' '-')" "git diff $mode" ;;
  *) git ls-files -- "$@" | emit path "path-$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-')" "none; read the files directly" ;;
esac
