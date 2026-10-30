#!/usr/bin/env bash
# Reports every git worktree and whether it's safe to remove. Only fetches.
# Usage: scan.sh [--no-fetch] [--no-gh] [--only <worktree>] [repo ...]
# With no repos, checks this one plus every repo Claude has worked in.
# Prints a repo block, a key: value block per worktree, then a summary line.
# class is active, pool, merged, ask, or unknown. Only merged is safe to remove unasked.
# Anything used in the last CLEANUP_RECENT_HOURS (default 24) counts as active.
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export GIT_TERMINAL_PROMPT=0

fetch=true
use_gh=true
recent_hours=${CLEANUP_RECENT_HOURS:-24}
only=
repos=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-fetch) fetch=false ;;
    --no-gh) use_gh=false ;;
    --only)
      only=${2:-}
      shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) repos+=("$1") ;;
  esac
  shift
done
case "$recent_hours" in '' | *[!0-9]*) echo "CLEANUP_RECENT_HOURS expects a number" >&2; exit 2 ;; esac
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v gh >/dev/null || use_gh=false

app="$HOME/Library/Application Support/Claude"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
now=$(date +%s)
recent_minutes=$((recent_hours * 60))

# --- What's running and who holds what, gathered once
# read collapses empty tab-separated fields, so every optional field gets a -.

: > "$tmp/live" ; : > "$tmp/chats" ; : > "$tmp/known"
for record in "$HOME"/.claude/sessions/*.json; do
  [ -f "$record" ] || continue
  jq -r '[.cwd // "-", .pid // 0, .status // "unknown"] | @tsv' "$record" 2>/dev/null
done | while IFS=$'\t' read -r cwd pid status; do
  [ "$cwd" != - ] || continue
  echo "$cwd" >> "$tmp/known"
  kill -0 "$pid" 2>/dev/null && printf '%s\t%s\n' "$cwd" "Claude session $pid ($status)" >> "$tmp/live"
done

lsof -d cwd -Fcn 2>/dev/null | awk '
  /^c/ { name = substr($0, 2) }
  /^n/ { print substr($0, 2) "\t" name }' >> "$tmp/live"

if [ -d "$app/claude-code-sessions" ]; then
  find "$app/claude-code-sessions" -name 'local_*.json' -type f -print0 |
    xargs -0 jq -r '[.cwd // "-", .originCwd // "-", (.isArchived == true), .lastActivityAt // 0, .sessionId // "-", .title // "-"] | @tsv' 2>/dev/null |
    while IFS=$'\t' read -r cwd origin archived active id title; do
      printf '%s\n%s\n' "$cwd" "$origin" >> "$tmp/known"
      [ "$archived" = false ] && printf '%s\t%s\t%s\t%s\n' "$cwd" "$active" "$id" "$title" >> "$tmp/chats"
    done
fi

# The app's registry. A worktree it holds with no lease is its reuse pool.
: > "$tmp/pool"
if [ -f "$app/git-worktrees.json" ]; then
  jq -r '.worktrees[]? | select(.leasedBy == null) | .path // empty' "$app/git-worktrees.json" 2>/dev/null > "$tmp/pool"
  jq -r '.worktrees[]?.path // empty' "$app/git-worktrees.json" 2>/dev/null >> "$tmp/known"
fi
[ -f "$HOME/.claude/history.jsonl" ] && jq -r '.project // empty' "$HOME/.claude/history.jsonl" 2>/dev/null >> "$tmp/known"

matching() { awk -F'\t' -v p="$2" '$1 == p || index($1, p "/") == 1' "$1"; }

transcript_recent() {
  [ "$recent_hours" -gt 0 ] || return 1
  local dir="$HOME/.claude/projects/$(printf '%s' "$1" | sed 's/[^A-Za-z0-9-]/-/g')"
  [ -d "$dir" ] && [ -n "$(find "$dir" -maxdepth 1 -name '*.jsonl' -mmin "-$recent_minutes" -print -quit 2>/dev/null)" ]
}

# Files in the top folder, so a worktree made moments ago doesn't look abandoned.
touched_recently() {
  [ "$recent_hours" -gt 0 ] || return 1
  [ -n "$(find "$1" -mindepth 1 -maxdepth 1 -mmin "-$recent_minutes" -print -quit 2>/dev/null)" ]
}

# Ignored files only this worktree has, leaving out what a build or install recreates.
leftovers() {
  git -C "$1" ls-files -oi --exclude-standard --directory 2>/dev/null |
    grep -Ev '(^|/)(node_modules|\.next[^/]*|\.nuxt|\.expo|\.turbo|\.cache|\.gradle|\.godot|\.pytest_cache|\.venv|venv|__pycache__|dist|build|out|target|coverage|vendor|Pods|DerivedData|playwright-report|test-results)(/|$)|(^|/)\.DS_Store$|(^|/)next-env\.d\.ts$|\.(log|tsbuildinfo|pyc)$' |
    while IFS= read -r file; do
      [ -e "$2/${file%/}" ] || printf '%s\n' "$file"
    done
}

# Sets pr_note, and how when a merged PR's head is exactly this commit.
check_pr() {
  local repo=$1 head=$2 branch=$3 prs open merged
  pr_note=
  [ "$use_gh" = true ] || return
  git -C "$repo" remote get-url origin 2>/dev/null | grep -q github || return
  if [ "$branch" = - ]; then
    prs=$(cd "$repo" && gh pr list --search "$head" --state all --json number,state,headRefOid --limit 20 2>/dev/null)
  else
    prs=$(cd "$repo" && gh pr list --head "$branch" --state all --json number,state,headRefOid --limit 20 2>/dev/null)
  fi || { pr_note=unknown; return; }
  open=$(printf '%s' "$prs" | jq -r 'map(select(.state == "OPEN"))[0].number // empty')
  if [ -n "$open" ]; then
    pr_note="open #$open"
    return
  fi
  merged=$(printf '%s' "$prs" | jq -r --arg head "$head" 'map(select(.state == "MERGED" and .headRefOid == $head))[0].number // empty')
  if [ -n "$merged" ]; then
    how="pr#$merged"
    pr_note="merged #$merged"
    return
  fi
  merged=$(printf '%s' "$prs" | jq -r 'map(select(.state == "MERGED"))[0].number // empty')
  [ -n "$merged" ] && pr_note="merged #$merged, but this has later commits"
  return 0
}

count_active=0 count_pool=0 count_merged=0 count_ask=0 count_unknown=0

report_worktree() {
  local repo=$1 base=$2 path=$3 head=$4 branch=$5 state=$6
  local class= why= dirty unique local_only stray_files chat_line chat_active chat_id chat_title live size
  how=
  pr_note=

  if ! git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    printf 'worktree: %s\nclass: unknown\nwhy: git cannot read this worktree\n\n' "$path"
    count_unknown=$((count_unknown + 1))
    return
  fi

  how=$(merged_how "$repo" "$base" "$head")
  [ -n "$how" ] || check_pr "$repo" "$head" "$branch"
  dirty=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  unique=$(git -C "$repo" rev-list --count "$base..$head" 2>/dev/null || echo '?')
  local_only=$(git -C "$repo" rev-list --count "$head" --not --remotes 2>/dev/null || echo '?')
  stray_files=$(leftovers "$path" "$repo")
  live=$(matching "$tmp/live" "$path" | cut -f2 | sort -u | paste -sd ',' - | sed 's/,/, /g')
  chat_line=$(matching "$tmp/chats" "$path" | sort -t$'\t' -k2,2nr | head -n 1)
  chat_active=$(printf '%s' "$chat_line" | cut -f2)
  chat_id=$(printf '%s' "$chat_line" | cut -f3)
  chat_title=$(printf '%s' "$chat_line" | cut -f4)

  if [ "$state" = locked ]; then
    class=active why="git has it locked"
  elif [ -n "$live" ]; then
    class=active why="in use by $live"
  elif [ -n "$chat_active" ] && [ $((now - chat_active / 1000)) -lt $((recent_hours * 3600)) ]; then
    class=active why="chat used in the last $recent_hours hours"
  elif transcript_recent "$path"; then
    class=active why="chat used in the last $recent_hours hours"
  elif touched_recently "$path"; then
    class=active why="files changed in the last $recent_hours hours"
  elif grep -qxF "$path" "$tmp/pool" && [ "$dirty" = 0 ] && { [ -n "$how" ] || [ "$unique" = 0 ]; }; then
    class=pool why="the app keeps this ready for new sessions and clears it itself"
  elif [ -z "$how" ]; then
    class=ask why="work isn't merged"
  elif [ "$dirty" != 0 ]; then
    class=ask why="merged, but has uncommitted changes"
  elif [ -n "$stray_files" ]; then
    class=ask why="merged, but holds ignored files that would be lost"
  elif [ -n "$chat_id" ]; then
    class=ask why="merged, but its chat is still open"
  else
    class=merged why="merged and nothing else is using it"
  fi

  size=$(du -sh "$path" 2>/dev/null | cut -f1 | tr -d ' ')

  echo "worktree: $path"
  echo "class: $class"
  echo "why: $why"
  echo "branch: $([ "$branch" = - ] && echo detached || echo "$branch")"
  echo "head: $head"
  echo "merged: ${how:-no}"
  echo "unique_commits: $unique"
  echo "local_only_commits: $local_only"
  echo "uncommitted: $dirty"
  echo "last_commit: $(git -C "$path" log -1 --format='%cs %s' 2>/dev/null | cut -c1-100)"
  echo "size: $size"
  [ -n "$pr_note" ] && echo "pr: $pr_note"
  [ -n "$chat_id" ] && echo "chat: $chat_id $(date -r $((chat_active / 1000)) +%F 2>/dev/null) $chat_title"
  if [ -n "$stray_files" ]; then
    echo "ignored_files: $(printf '%s\n' "$stray_files" | wc -l | tr -d ' ') ($(printf '%s\n' "$stray_files" | head -n 5 | paste -sd ',' - | sed 's/,/, /g'))"
  fi
  echo

  case "$class" in
    active) count_active=$((count_active + 1)) ;;
    pool) count_pool=$((count_pool + 1)) ;;
    merged) count_merged=$((count_merged + 1)) ;;
    ask) count_ask=$((count_ask + 1)) ;;
  esac
}

report_repo() {
  local repo=$1 base fetched=skipped path head branch state primary=true unique checked_out how track name
  git -C "$repo" worktree list --porcelain 2>/dev/null | grep -q '^bare$' && return
  base=$(base_ref "$repo") || {
    printf 'repo: %s\nnote: no main branch found, so nothing here can be judged\n\n' "$repo"
    return
  }

  if [ "$fetch" = true ] && git -C "$repo" remote get-url origin >/dev/null 2>&1 &&
    { [ "$(list_worktrees "$repo" | wc -l)" -gt 1 ] || [ "$(git -C "$repo" for-each-ref --count=2 refs/heads | wc -l)" -gt 1 ]; }; then
    git -C "$repo" fetch -q --prune origin 2>/dev/null && fetched=ok || fetched=failed
  fi

  if [ -z "$only" ]; then
    echo "repo: $repo"
    echo "base: $base"
    echo "fetch: $fetched"
    echo
  fi

  list_worktrees "$repo" > "$tmp/worktrees"
  while IFS=$'\t' read -r path head branch state; do
    if [ "$primary" = true ]; then
      primary=false
      continue
    fi
    [ -z "$only" ] || [ "$path" = "$only" ] || continue
    if [ "$state" = prunable ]; then
      [ -n "$only" ] && continue
      unique=$(git -C "$repo" rev-list --count "$base..$head" 2>/dev/null || echo '?')
      echo "prunable: $path $head unique_commits=$unique"
      continue
    fi
    report_worktree "$repo" "$base" "$path" "$head" "$branch" "$state"
  done < "$tmp/worktrees"
  [ -z "$only" ] || return

  local holder="$repo/.claude/worktrees" entry
  if [ -d "$holder" ]; then
    for entry in "$holder"/* "$holder"/.[!.]*; do
      [ -e "$entry" ] && [ "$(basename "$entry")" != .DS_Store ] || continue
      cut -f1 "$tmp/worktrees" | grep -qxF "$entry" || echo "stray: $entry"
    done
  fi

  checked_out=$(cut -f3 "$tmp/worktrees")
  local other=0
  while IFS=$'\t' read -r name track; do
    [ "$name" != "${base#origin/}" ] || continue
    printf '%s\n' "$checked_out" | grep -qxF "$name" && continue
    how=$(merged_how "$repo" "$base" "refs/heads/$name")
    if [ -n "$how" ]; then
      echo "branch_merged: $name ($how)"
    elif [ "$track" = '[gone]' ]; then
      echo "branch_gone: $name"
    else
      other=$((other + 1))
    fi
  done < <(git -C "$repo" for-each-ref --format='%(refname:short)%09%(upstream:track)' refs/heads)
  echo "branches_unmerged: $other"
  echo "stashes: $(git -C "$repo" stash list 2>/dev/null | wc -l | tr -d ' ')"
  echo
}

# --- Which repos

if [ -n "$only" ]; then
  [ -d "$only" ] || { printf 'worktree: %s\nclass: unknown\nwhy: folder not found\n' "$only"; exit 0; }
  only=$(cd "$only" && pwd -P)
  repos=("$only")
elif [ "${#repos[@]}" -eq 0 ]; then
  repos=(.)
  while IFS= read -r known; do repos+=("$known"); done < <(sort -u "$tmp/known")
fi

for candidate in "${repos[@]}"; do
  [ -d "$candidate" ] && primary_of "$candidate"
done | sort -u > "$tmp/repos"

if [ ! -s "$tmp/repos" ] && [ -n "$only" ]; then
  printf 'worktree: %s\nclass: unknown\nwhy: not a git worktree\n' "$only"
  exit 0
fi

while IFS= read -r repo; do
  [ -n "$repo" ] && report_repo "$repo"
done < "$tmp/repos"

[ -n "$only" ] || echo "summary: active=$count_active pool=$count_pool merged=$count_merged ask=$count_ask unknown=$count_unknown"
