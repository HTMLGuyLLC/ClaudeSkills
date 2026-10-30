#!/usr/bin/env bash
# Works out what /audit should look at.
# Usage: scope.sh [auto|uncommitted|branch|pr [n]|last [n]|all|<a..b>|<path>...]
# Prints mode, label, diff_cmd, any note lines, count, then one file per line.
# Exits non-zero on any failure, so a failure can't look like an empty scope.
set -uo pipefail

die() { echo "error: $*" >&2; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "not a git repository; read the paths directly without this script"
fi
prefix=$(git rev-parse --show-prefix)
start_dir=$PWD
cd "$(git rev-parse --show-toplevel)" || exit 1

g() { git -c core.quotePath=false "$@"; }
slug() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'; }
empty_tree() { git hash-object -t tree /dev/null; }
has_commits() { git rev-parse --verify --quiet HEAD >/dev/null; }

notes=()
also_ahead=

# The current branch's PR knows its real base, which may not be the default branch.
pr_base() {
  command -v gh >/dev/null 2>&1 || return 1
  gh pr view --json baseRefName --jq .baseRefName 2>/dev/null
}

base_branch() {
  local ref
  ref=$(pr_base) && [ -n "$ref" ] && { echo "$ref"; return; }
  ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null) && { echo "${ref#refs/remotes/origin/}"; return; }
  for ref in main master; do
    git show-ref --verify --quiet "refs/heads/$ref" && { echo "$ref"; return; }
  done
  return 1
}

base_ref() {
  local base
  base=$(base_branch) || return 1
  if git show-ref --verify --quiet "refs/remotes/origin/$base"; then echo "origin/$base"; else echo "$base"; fi
}

is_dirty() { [ -n "$(git status --porcelain)" ]; }

ahead_count() {
  local base
  base=$(base_ref) || { echo 0; return; }
  git rev-list --count "$base..HEAD" 2>/dev/null || echo 0
}

current_pr() {
  command -v gh >/dev/null 2>&1 || return 1
  gh pr view --json number --jq .number 2>/dev/null
}

latest_merged_pr() {
  command -v gh >/dev/null 2>&1 || return 1
  gh pr list --state merged --limit 1 --json number --jq '.[0].number // empty' 2>/dev/null
}

emit() { # mode label diff_cmd files
  local count
  count=$(printf '%s\n' "$4" | sed '/^$/d' | sort -u | grep -c . || true)
  echo "mode: $1"
  echo "label: $2"
  echo "diff_cmd: $3"
  [ -z "$also_ahead" ] || [ "$also_ahead" = 0 ] || echo "also_ahead: $also_ahead commits not included"
  local note
  for note in ${notes[@]+"${notes[@]}"}; do echo "note: $note"; done
  echo "count: $count"
  echo "files:"
  printf '%s\n' "$4" | sed '/^$/d' | sort -u
}

scope_uncommitted() {
  local tracked untracked
  if has_commits; then
    also_ahead=$(ahead_count)
    tracked=$(g diff --name-only HEAD) || die "git diff failed"
  else
    tracked=$(g diff --cached --name-only) || die "git diff failed"
  fi
  untracked=$(g ls-files --others --exclude-standard) || die "git ls-files failed"
  emit uncommitted uncommitted "git diff HEAD (plus any untracked files listed)" "$tracked"$'\n'"$untracked"
}

scope_branch() {
  local base files range
  base=$(base_ref) || die "no base branch found; pass a range such as develop..HEAD"
  range="$base...HEAD"
  if ! git merge-base "$base" HEAD >/dev/null 2>&1; then
    range="$base HEAD"
    notes+=("no merge base with $base, so this compares the two tips and may include unrelated changes")
  fi
  # shellcheck disable=SC2086 # range is one or two refs
  files=$(g diff --name-only $range) || die "git diff $range failed"
  emit branch "branch-$(slug "$(git branch --show-current)")" "git diff $range" "$files"
}

scope_pr() {
  local number=${1:-} files
  command -v gh >/dev/null 2>&1 || die "gh is needed to audit a PR"
  [ -n "$number" ] || number=$(current_pr) || number=
  [ -n "$number" ] || number=$(latest_merged_pr) || number=
  [ -n "$number" ] || die "no PR found; check gh auth status or pass a number"
  files=$(gh pr diff "$number" --name-only) || die "gh pr diff $number failed"
  emit pr "pr-$number" "gh pr diff $number" "$files"
}

scope_last() {
  local n=${1:-1} from files
  case "$n" in ''|*[!0-9]*) die "last expects a number, got: $n" ;; esac
  has_commits || die "this repository has no commits"
  from="HEAD~$n"
  if ! git rev-parse --verify --quiet "$from" >/dev/null; then
    from=$(empty_tree)
    notes+=("the history is shorter than $n commits, so this covers all of it")
  fi
  files=$(g diff --name-only "$from" HEAD) || die "git diff failed"
  emit commits "last-$n-commits" "git diff $from HEAD" "$files"
}

scope_paths() {
  local paths=() p files
  for p in "$@"; do
    case "$p" in /*) paths+=("$p") ;; *) paths+=("$prefix$p") ;; esac
  done
  files=$(g ls-files --cached --others --exclude-standard -- "${paths[@]}") || die "git ls-files failed"
  [ -n "$files" ] || die "no files found at: $*"
  emit path "path-$(slug "$1")" "none; read the files directly" "$files"
}

mode=${1:-auto}
case "$mode" in -*) die "unknown option: $mode" ;; esac

case "$mode" in
  auto)
    if is_dirty; then scope_uncommitted
    elif ! has_commits; then die "this repository has no commits or changes"
    elif [ "$(ahead_count)" -gt 0 ]; then scope_branch
    else
      pr=$(current_pr) || pr=
      [ -n "$pr" ] || pr=$(latest_merged_pr) || pr=
      if [ -n "$pr" ]; then scope_pr "$pr"
      else
        notes+=("no PR found, or gh isn't available, so this covers only the last commit")
        scope_last 1
      fi
    fi ;;
  uncommitted) scope_uncommitted ;;
  branch) scope_branch ;;
  pr) scope_pr "${2:-}" ;;
  last) scope_last "${2:-1}" ;;
  all) files=$(g ls-files) || die "git ls-files failed"; emit all full-repo "none; read the files directly" "$files" ;;
  *)
    # A real path wins, because names like app/[...slug] contain "..".
    if [ -e "$start_dir/$mode" ] || [ -e "$mode" ] || [[ "$mode" != *..* ]]; then
      scope_paths "$@"
    else
      files=$(g diff --name-only "$mode") || die "not a valid range or path: $mode"
      emit range "range-$(slug "$mode")" "git diff $mode" "$files"
    fi ;;
esac
