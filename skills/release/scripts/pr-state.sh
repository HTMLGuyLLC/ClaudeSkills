#!/usr/bin/env bash
# Prints whether a PR is ready to merge. Read-only.
# Usage: pr-state.sh [--ignore-copilot] [pr number]; defaults to the current branch's PR.
# --ignore-copilot is for after the Copilot wait has timed out; the output says it was used.
set -uo pipefail

ignore_copilot=
pr=
for arg in "$@"; do
  case "$arg" in
    --ignore-copilot) ignore_copilot=1 ;;
    *[!0-9]*|'') echo "error: expected a PR number, got: $arg" >&2; exit 2 ;;
    *) pr=$arg ;;
  esac
done

info=$(gh pr view ${pr:+"$pr"} --json number,url,state,isDraft,headRefOid,headRefName,mergeable,mergeStateStatus,reviewDecision,reviewRequests,latestReviews --jq '
  .headRefOid as $head
  | ([.latestReviews[] | select(.author.login | test("copilot"; "i"))]) as $copilot
  | [ "number: \(.number)",
      "url: \(.url)",
      "state: \(.state)",
      "draft: \(.isDraft)",
      "head: \($head)",
      "head_branch: \(.headRefName)",
      "mergeable: \(.mergeable)",
      "merge_state: \(.mergeStateStatus)",
      "review_decision: \(.reviewDecision)",
      "pending_reviewers: \([.reviewRequests[] | .login // .name // .slug // "unknown"] | join(", "))",
      "copilot_review: \(if ($copilot | length) == 0 then "none" elif any($copilot[]; .commit.oid == $head) then "current" else "stale" end)"
    ] | join("\n")') || exit 1
echo "$info"

value() { printf '%s\n' "$info" | sed -n "s/^$1: //p"; }
number=$(value number)

# gh exits non-zero for failing or pending checks as well as for real errors,
# so read the output first and fall back to stderr only when there is none.
stderr_file=$(mktemp)
trap 'rm -f "$stderr_file"' EXIT
checks=$(gh pr checks "$number" --json name,bucket --jq '
  [ "checks_passed: \([.[] | select(.bucket == "pass")] | length)",
    "checks_failed: \([.[] | select(.bucket == "fail" or .bucket == "cancel") | .name] | join(", "))",
    "checks_pending: \([.[] | select(.bucket == "pending") | .name] | join(", "))"
  ] | join("\n")' 2>"$stderr_file") || true

checks_state=known
if [ -z "$checks" ]; then
  checks=$'checks_passed: 0\nchecks_failed: \nchecks_pending: '
  if ! grep -q 'no checks reported' "$stderr_file"; then
    checks_state=unknown
  elif workflows="$(git rev-parse --show-toplevel 2>/dev/null)/.github/workflows" && [ -d "$workflows" ] && grep -rqE 'pull_request|branches:' "$workflows" 2>/dev/null; then
    checks_state=not-registered
  else
    checks_state=no-ci
  fi
fi
echo "$checks"
echo "checks_state: $checks_state"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || exit 1
threads=$(gh api graphql -F owner="${repo%/*}" -F name="${repo#*/}" -F number="$number" -f query='
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          pageInfo { hasNextPage }
          nodes { id isResolved path line comments(first: 1) { nodes { author { login } } } }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads
    | (if .pageInfo.hasNextPage then "more_threads: yes" else empty end),
      (.nodes[] | select(.isResolved | not) | "\(.id) \(.comments.nodes[0].author.login) \(.path):\(.line)")') || exit 1
more_threads=$(printf '%s\n' "$threads" | grep -c '^more_threads: ' || true)
threads=$(printf '%s\n' "$threads" | grep -v '^more_threads: ' || true)
unresolved=$(printf '%s' "$threads" | grep -c . || true)
echo "unresolved_threads: $unresolved"
[ -z "$threads" ] || printf '%s\n' "$threads"

failed=$(printf '%s\n' "$checks" | sed -n 's/^checks_failed: //p')
pending=$(printf '%s\n' "$checks" | sed -n 's/^checks_pending: //p')
copilot_review=$(value copilot_review)
reviewers=$(value pending_reviewers)
others=$(printf '%s\n' "$reviewers" | tr ',' '\n' | sed 's/^ *//' | grep -iv copilot | paste -sd, - || true)

reasons=()
[ "$(value state)" = OPEN ] || reasons+=("not open")
[ "$(value draft)" = false ] || reasons+=("draft")
[ "$(value mergeable)" = MERGEABLE ] || reasons+=("mergeable is $(value mergeable)")
case "$(value merge_state)" in BLOCKED|BEHIND|DIRTY|DRAFT) reasons+=("merge state is $(value merge_state)") ;; esac
[ "$(value review_decision)" != CHANGES_REQUESTED ] || reasons+=("changes requested")
[ -z "$failed" ] || reasons+=("checks failed")
[ -z "$pending" ] || reasons+=("checks pending")
[ "$checks_state" != unknown ] || reasons+=("checks unknown")
[ "$checks_state" != not-registered ] || reasons+=("no checks on this commit yet")
[ "$unresolved" = 0 ] || reasons+=("unresolved threads")
[ "$more_threads" = 0 ] || reasons+=("over 100 review threads")
[ -z "$others" ] || reasons+=("review pending from $others")

if [ "$(git branch --show-current 2>/dev/null)" = "$(value head_branch)" ] &&
  [ "$(git rev-parse HEAD 2>/dev/null)" != "$(value head)" ]; then
  reasons+=("local HEAD differs from PR head")
fi

if [ -n "$ignore_copilot" ]; then
  echo "copilot_ignored: yes"
else
  [ "$copilot_review" != stale ] || reasons+=("Copilot hasn't reviewed the latest commit")
  case "$reviewers" in *[Cc]opilot*) reasons+=("Copilot review pending") ;; esac
fi

if [ ${#reasons[@]} -eq 0 ]; then
  echo "ready: yes"
else
  printf 'ready: no ('; (IFS=';'; printf '%s' "${reasons[*]}"); echo ')'
fi
