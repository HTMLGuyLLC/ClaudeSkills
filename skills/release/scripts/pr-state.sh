#!/usr/bin/env bash
# Prints whether a PR is ready to merge. Read-only.
# Usage: pr-state.sh [pr number, url, or branch]; defaults to the current branch's PR.
set -uo pipefail

pr=${1:-}
info=$(gh pr view ${pr:+"$pr"} --json number,url,state,isDraft,headRefOid,mergeable,mergeStateStatus,reviewDecision,reviewRequests,latestReviews --jq '
  .headRefOid as $head
  | ([.latestReviews[] | select(.author.login | test("copilot"; "i"))]) as $copilot
  | [ "number: \(.number)",
      "url: \(.url)",
      "state: \(.state)",
      "draft: \(.isDraft)",
      "head: \($head)",
      "mergeable: \(.mergeable)",
      "merge_state: \(.mergeStateStatus)",
      "review_decision: \(.reviewDecision)",
      "pending_reviewers: \([.reviewRequests[] | .login // .name // .slug // "unknown"] | join(", "))",
      "copilot_review: \(if ($copilot | length) == 0 then "none" elif any($copilot[]; .commit.oid == $head) then "current" else "stale" end)"
    ] | join("\n")') || exit 1
echo "$info"

value() { printf '%s\n' "$info" | sed -n "s/^$1: //p"; }
number=$(value number)

checks=$(gh pr checks "$number" --json name,bucket --jq '
  [ "checks_passed: \([.[] | select(.bucket == "pass")] | length)",
    "checks_failed: \([.[] | select(.bucket == "fail" or .bucket == "cancel") | .name] | join(", "))",
    "checks_pending: \([.[] | select(.bucket == "pending") | .name] | join(", "))"
  ] | join("\n")' 2>/dev/null) || true
[ -n "$checks" ] || checks=$'checks_passed: 0\nchecks_failed: \nchecks_pending: '
echo "$checks"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
threads=$(gh api graphql -F owner="${repo%/*}" -F name="${repo#*/}" -F number="$number" -f query='
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes { id isResolved path line comments(first: 1) { nodes { author { login } } } }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | "\(.id) \(.comments.nodes[0].author.login) \(.path):\(.line)"') || exit 1
unresolved=$(printf '%s' "$threads" | grep -c . || true)
echo "unresolved_threads: $unresolved"
[ -z "$threads" ] || printf '%s\n' "$threads"

failed=$(printf '%s\n' "$checks" | sed -n 's/^checks_failed: //p')
pending=$(printf '%s\n' "$checks" | sed -n 's/^checks_pending: //p')
reasons=()
[ "$(value state)" = OPEN ] || reasons+=("not open")
[ "$(value draft)" = false ] || reasons+=("draft")
[ "$(value mergeable)" = MERGEABLE ] || reasons+=("mergeable is $(value mergeable)")
case "$(value merge_state)" in BLOCKED|DIRTY|DRAFT) reasons+=("merge state is $(value merge_state)") ;; esac
[ "$(value review_decision)" != CHANGES_REQUESTED ] || reasons+=("changes requested")
[ -z "$failed" ] || reasons+=("checks failed")
[ -z "$pending" ] || reasons+=("checks pending")
[ "$unresolved" = 0 ] || reasons+=("unresolved threads")
[ "$(value copilot_review)" != stale ] || reasons+=("Copilot hasn't reviewed the latest commit")
case "$(value pending_reviewers)" in *[Cc]opilot*) reasons+=("Copilot review pending") ;; esac

if [ ${#reasons[@]} -eq 0 ]; then
  echo "ready: yes"
else
  printf 'ready: no ('; (IFS=';'; printf '%s' "${reasons[*]}"); echo ')'
fi
