#!/usr/bin/env bash
# Removes what scan.sh reported, rechecking first in case anything changed since.
# Usage:
#   remove.sh worktree <path> [--approved] [--save-changes | --discard-changes] [--delete-branch]
#   remove.sh branch <repo> <name> [--approved]
#   remove.sh prune <repo>
#   remove.sh stray <path> --approved
# --approved means the user said yes to this exact item. Commits a detached
# worktree alone holds always go to a rescue branch first.
set -uo pipefail
here=$(dirname "${BASH_SOURCE[0]}")
. "$here/lib.sh"

die() { echo "refused: $*" >&2; exit 1; }

field() { printf '%s\n' "$1" | sed -n "s/^$2: //p" | head -n 1; }

remove_worktree() {
  local path=${1:-} approved=false changes= delete_branch=false
  [ -n "$path" ] || die "no worktree given"
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --approved) approved=true ;;
      --save-changes) changes=save ;;
      --discard-changes) changes=discard ;;
      --delete-branch) delete_branch=true ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  local report class why repo base branch head how unique dirty name rescue
  report=$("$here/scan.sh" --no-fetch --only "$path")
  class=$(field "$report" class)
  why=$(field "$report" why)
  [ -n "$class" ] || die "$path isn't a linked worktree"
  path=$(cd "$path" 2>/dev/null && pwd -P) || die "$why"
  case "$class" in
    merged) ;;
    ask) [ "$approved" = true ] || die "$path needs approval: $why" ;;
    *) die "$path: $why" ;;
  esac

  repo=$(primary_of "$path")
  [ "$repo" != "$path" ] || die "$path is the repo's main folder"
  base=$(base_ref "$repo") || die "no main branch found in $repo"
  branch=$(field "$report" branch)
  head=$(field "$report" head)
  how=$(field "$report" merged)
  unique=$(field "$report" unique_commits)
  dirty=$(field "$report" uncommitted)
  name=$(basename "$path")

  if [ "$dirty" != 0 ] && [ -z "$changes" ]; then
    die "$path has $dirty uncommitted changes, so pass --save-changes or --discard-changes"
  fi
  if [ "$branch" = detached ] && [ "$how" = no ] && [ "$unique" != 0 ]; then
    rescue=$(rescue_name "$path" "$head")
    git -C "$repo" rev-parse -q --verify "refs/heads/$rescue" >/dev/null ||
      git -C "$repo" branch "$rescue" "$head" || die "couldn't save commits to $rescue"
    echo "rescued: $rescue"
  fi
  if [ "$dirty" != 0 ] && [ "$changes" = save ]; then
    git -C "$path" stash push -q -u -m "cleanup: $name" || die "couldn't stash $path, so it was kept"
    echo "stashed: cleanup: $name"
  fi

  if [ "$changes" = discard ]; then
    git -C "$repo" worktree remove --force "$path" || die "git couldn't remove $path"
  else
    git -C "$repo" worktree remove "$path" || die "git couldn't remove $path"
  fi
  echo "removed: $path"

  [ "$branch" != detached ] || return 0
  if [ "$how" != no ] || [ "$delete_branch" = true ]; then
    git -C "$repo" branch -q -D "$branch" && echo "deleted_branch: $branch"
  else
    echo "kept_branch: $branch"
  fi
}

remove_branch() {
  local repo=${1:-} name=${2:-} approved=${3:-} base how track
  [ -n "$repo" ] && [ -n "$name" ] || die "needs a repo and a branch"
  base=$(base_ref "$repo") || die "no main branch found in $repo"
  [ "$name" != "${base#origin/}" ] || die "$name is the main branch"
  git -C "$repo" rev-parse -q --verify "refs/heads/$name" >/dev/null || die "no branch named $name"
  how=$(merged_how "$repo" "$base" "refs/heads/$name")
  if [ -z "$how" ] && [ "$approved" != --approved ]; then
    track=$(git -C "$repo" for-each-ref --format='%(upstream:track)' "refs/heads/$name")
    die "$name isn't merged${track:+ (upstream $track)}, so it needs approval"
  fi
  git -C "$repo" branch -q -D "$name" || die "git couldn't delete $name"
  echo "deleted_branch: $name"
}

prune_records() {
  local repo=${1:-} base path head branch state rescue
  [ -n "$repo" ] || die "needs a repo"
  base=$(base_ref "$repo") || die "no main branch found in $repo"
  while IFS=$'\t' read -r path head branch state; do
    [ "$state" = prunable ] || continue
    if [ "$branch" = - ] && [ -z "$(merged_how "$repo" "$base" "$head")" ]; then
      rescue=$(rescue_name "$path" "$head")
      git -C "$repo" rev-parse -q --verify "refs/heads/$rescue" >/dev/null ||
        git -C "$repo" branch "$rescue" "$head" || die "couldn't save commits to $rescue"
      echo "rescued: $rescue"
    fi
    echo "pruned: $path"
  done < <(list_worktrees "$repo")
  git -C "$repo" worktree prune
}

remove_stray() {
  local path=${1:-} approved=${2:-}
  [ "$approved" = --approved ] || die "stray files need approval"
  case "$path" in
    */.claude/worktrees/*) ;;
    *) die "$path isn't under .claude/worktrees" ;;
  esac
  [ -e "$path" ] || die "$path doesn't exist"
  [ ! -e "$path/.git" ] || die "$path is a git worktree or repo"
  rm -rf -- "$path"
  echo "removed: $path"
}

action=${1:-}
[ $# -eq 0 ] || shift
case "$action" in
  worktree) remove_worktree "$@" ;;
  branch) remove_branch "$@" ;;
  prune) prune_records "$@" ;;
  stray) remove_stray "$@" ;;
  *) die "expected worktree, branch, prune, or stray" ;;
esac
