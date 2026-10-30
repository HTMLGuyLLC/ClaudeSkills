#!/usr/bin/env bash
# Shared by scan.sh and remove.sh, so both judge a worktree the same way.

# Prints the branch that counts as "landed": origin's default, else main or master.
base_ref() {
  local repo=$1 ref
  ref=$(git -C "$repo" symbolic-ref -q --short refs/remotes/origin/HEAD) && { echo "$ref"; return; }
  for ref in origin/main origin/master main master; do
    git -C "$repo" rev-parse -q --verify "$ref^{commit}" >/dev/null && { echo "$ref"; return; }
  done
  return 1
}

# Prints how <ref> reached <base>: ancestor, patch, or no-diff. Prints nothing if it didn't.
# patch and no-diff catch squash and rebase merges, which ancestry can't see.
merged_how() {
  local repo=$1 base=$2 ref=$3 cherry tree
  if git -C "$repo" merge-base --is-ancestor "$ref" "$base" 2>/dev/null; then
    echo ancestor
    return
  fi
  if cherry=$(git -C "$repo" cherry "$base" "$ref" 2>/dev/null) && [ -n "$cherry" ] &&
    ! printf '%s\n' "$cherry" | grep -q '^+'; then
    echo patch
    return
  fi
  if tree=$(git -C "$repo" merge-tree --write-tree "$base" "$ref" 2>/dev/null) &&
    [ "$(printf '%s\n' "$tree" | head -n 1)" = "$(git -C "$repo" rev-parse "$base^{tree}")" ]; then
    echo no-diff
  fi
}

# Prints one tab-separated line per worktree: path, head, branch or -, then
# bare, locked, prunable, or -. The primary worktree comes first.
list_worktrees() {
  git -C "$1" worktree list --porcelain 2>/dev/null | awk '
    function flush() { if (path != "") print path "\t" head "\t" branch "\t" state; path = "" }
    /^worktree / { flush(); path = substr($0, 10); head = "-"; branch = "-"; state = "-"; next }
    /^HEAD / { head = substr($0, 6); next }
    /^branch / { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch); next }
    /^bare$/ { state = "bare"; next }
    /^locked/ { state = "locked"; next }
    /^prunable/ { state = "prunable"; next }
    END { flush() }'
}

# Prints the main folder of the repo holding <path>.
primary_of() {
  git -C "$1" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p'
}

# Prints a branch name for commits that only a detached worktree holds.
rescue_name() {
  echo "rescue/$(basename "$1")-$(printf '%s' "$2" | cut -c1-8)"
}
