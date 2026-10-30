#!/usr/bin/env bash
# Offline tests for the bundled scripts. Needs only git and jq.
# Usage: tests/run.sh
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pr_state="$repo/skills/release/scripts/pr-state.sh"
scope="$repo/skills/audit/scripts/scope.sh"
scanners="$repo/skills/audit/scripts/scanners.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0
total=0

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

pass() { total=$((total + 1)); }
fail() { total=$((total + 1)); failures=$((failures + 1)); echo "FAIL: $1"; }

# expect <name> <needle> <output>
expect() { case "$3" in *"$2"*) pass ;; *) fail "$1: wanted '$2' in: $3" ;; esac; }
reject() { case "$3" in *"$2"*) fail "$1: didn't want '$2' in: $3" ;; *) pass ;; esac; }

new_repo() {
  local dir="$work/repo$RANDOM$RANDOM"
  mkdir -p "$dir" && git -C "$dir" init -q -b main
  echo "$dir"
}

# --- Stub gh: answers from env vars and applies --jq with the real jq.
stub="$work/bin"
mkdir -p "$stub"
cat > "$stub/gh" <<'STUB'
#!/usr/bin/env bash
jq_expr=
no_threads='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false},"nodes":[]}}}}}'
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [ "${args[$i]}" = --jq ] && jq_expr=${args[$((i + 1))]}
done
answer() { if [ -n "$jq_expr" ]; then printf '%s' "$1" | jq -r "$jq_expr"; else printf '%s\n' "$1"; fi; }
case "$1 $2" in
  "pr view") answer "${STUB_VIEW:?}" ;;
  "repo view") echo o/r ;;
  "api graphql") answer "${STUB_THREADS:-$no_threads}" ;;
  "pr checks")
    case "${STUB_CHECKS:-pass}" in
      pass) answer '[{"name":"ci","bucket":"pass"}]' ;;
      fail) answer '[{"name":"ci","bucket":"fail"}]'; exit 1 ;;
      pending) answer '[{"name":"ci","bucket":"pending"}]'; exit 8 ;;
      none) echo "no checks reported on the 'x' branch" >&2; exit 1 ;;
      error) echo 'HTTP 502: Bad Gateway' >&2; exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$stub/gh"

view() { # overrides merged onto a healthy PR
  local over=${1:-}
  [ -n "$over" ] || over='{}'
  jq -cn --argjson over "$over" '{
    number: 1, url: "u", state: "OPEN", isDraft: false, headRefOid: "abc", headRefName: "feature",
    mergeable: "MERGEABLE", mergeStateStatus: "CLEAN", reviewDecision: "",
    reviewRequests: [], latestReviews: []} + $over'
}

state() { # <dir> <view json> <checks mode> [args...]
  local dir=$1 json=$2 checks=$3; shift 3
  (cd "$dir" && PATH="$stub:$PATH" STUB_VIEW="$json" STUB_CHECKS="$checks" bash "$pr_state" "$@" 2>&1)
}

plain=$(new_repo)
ci=$(new_repo)
mkdir -p "$ci/.github/workflows"
printf 'on:\n  pull_request:\n' > "$ci/.github/workflows/ci.yml"
tags=$(new_repo)
mkdir -p "$tags/.github/workflows"
printf 'on:\n  push:\n    tags: [v*]\n' > "$tags/.github/workflows/release.yml"

# --- pr-state: the merge gate
healthy=$(view)
expect "passing checks" "ready: yes" "$(state "$plain" "$healthy" pass 1)"
expect "failing checks" "checks failed" "$(state "$plain" "$healthy" fail 1)"
expect "pending checks" "checks pending" "$(state "$plain" "$healthy" pending 1)"
expect "no CI at all" "ready: yes" "$(state "$plain" "$healthy" none 1)"
expect "no CI state" "checks_state: no-ci" "$(state "$plain" "$healthy" none 1)"
expect "tag-only workflow isn't PR CI" "ready: yes" "$(state "$tags" "$healthy" none 1)"
expect "CI not registered yet" "no checks on this commit yet" "$(state "$ci" "$healthy" none 1)"
expect "gh error fails closed" "checks unknown" "$(state "$plain" "$healthy" error 1)"
reject "gh error isn't ready" "ready: yes" "$(state "$plain" "$healthy" error 1)"
expect "pending person blocks" "review pending from alice" \
  "$(state "$plain" "$(view '{"reviewRequests":[{"login":"alice"}]}')" pass 1)"
expect "pending Copilot blocks" "Copilot review pending" \
  "$(state "$plain" "$(view '{"reviewRequests":[{"login":"Copilot"}]}')" pass 1)"
expect "ignore-copilot passes" "ready: yes" \
  "$(state "$plain" "$(view '{"reviewRequests":[{"login":"Copilot"}]}')" pass --ignore-copilot 1)"
expect "ignore-copilot is reported" "copilot_ignored: yes" \
  "$(state "$plain" "$(view '{"reviewRequests":[{"login":"Copilot"}]}')" pass --ignore-copilot 1)"
expect "ignore-copilot keeps people" "review pending from alice" \
  "$(state "$plain" "$(view '{"reviewRequests":[{"login":"Copilot"},{"login":"alice"}]}')" pass --ignore-copilot 1)"
stale='{"latestReviews":[{"author":{"login":"copilot-pull-request-reviewer"},"commit":{"oid":"old"}}]}'
expect "stale Copilot review blocks" "hasn't reviewed the latest commit" "$(state "$plain" "$(view "$stale")" pass 1)"
expect "changes requested blocks" "changes requested" \
  "$(state "$plain" "$(view '{"reviewDecision":"CHANGES_REQUESTED"}')" pass 1)"
expect "behind blocks" "merge state is BEHIND" "$(state "$plain" "$(view '{"mergeStateStatus":"BEHIND"}')" pass 1)"
expect "unknown mergeable blocks" "mergeable is UNKNOWN" "$(state "$plain" "$(view '{"mergeable":"UNKNOWN"}')" pass 1)"
expect "URL rejected" "expected a PR number" "$(state "$plain" "$healthy" pass https://github.com/o/r/pull/1)"

many='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":true},"nodes":[]}}}}}'
expect "over 100 threads blocks" "over 100 review threads" \
  "$(STUB_THREADS="$many" state "$plain" "$healthy" pass 1)"
open_thread='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false},"nodes":[{"id":"T1","isResolved":false,"path":"a","line":1,"comments":{"nodes":[{"author":{"login":"bob"}}]}}]}}}}}'
expect "open thread blocks" "unresolved threads" "$(STUB_THREADS="$open_thread" state "$plain" "$healthy" pass 1)"

git -C "$plain" commit -q --allow-empty -m one
git -C "$plain" switch -q -c feature
expect "local head mismatch blocks" "local HEAD differs from PR head" "$(state "$plain" "$healthy" pass 1)"
matching=$(view "{\"headRefOid\":\"$(git -C "$plain" rev-parse HEAD)\"}")
expect "local head match passes" "ready: yes" "$(state "$plain" "$matching" pass 1)"

# --- scope: failures must not look like an empty scope
s=$(new_repo)
echo a > "$s/a.txt"
out=$(cd "$s" && bash "$scope" 2>&1)
expect "unborn repo lists untracked" "a.txt" "$out"
git -C "$s" add a.txt
out=$(cd "$s" && bash "$scope" 2>&1)
expect "unborn repo lists staged" "count: 1" "$out"
git -C "$s" commit -q -m one

out=$(cd "$s" && bash "$scope" last 1 2>&1)
expect "first commit works" "a.txt" "$out"
out=$(cd "$s" && bash "$scope" last abc 2>&1); code=$?
expect "bad last errors" "expects a number" "$out"
[ "$code" != 0 ] && pass || fail "bad last should exit non-zero"
out=$(cd "$s" && bash "$scope" nope..nada 2>&1); code=$?
[ "$code" != 0 ] && pass || fail "bad range should exit non-zero"
out=$(cd "$s" && bash "$scope" --output=../x 2>&1); code=$?
expect "option rejected" "unknown option" "$out"
out=$(cd "$s" && bash "$scope" missing.txt 2>&1); code=$?
expect "missing path errors" "no files found" "$out"
[ "$code" != 0 ] && pass || fail "missing path should exit non-zero"

mkdir -p "$s/pkg/src" "$s/src" "$s/app/[...slug]"
echo x > "$s/pkg/src/a"; echo y > "$s/src/b"; echo z > "$s/app/[...slug]/page.tsx"
echo u > "$s/café.txt"
git -C "$s" add . && git -C "$s" commit -q -m two
out=$(cd "$s/pkg" && bash "$scope" src 2>&1)
expect "subfolder path is relative" "pkg/src/a" "$out"
reject "subfolder path skips root" "src/b" "$out"
out=$(cd "$s/pkg" && bash "$scope" ../src 2>&1)
expect "dotted path isn't a range" "src/b" "$out"
out=$(cd "$s" && bash "$scope" 'app/[...slug]/page.tsx' 2>&1)
expect "catch-all route path" "mode: path" "$out"
expect "catch-all route file" "count: 1" "$out"
out=$(cd "$s" && bash "$scope" last 1 2>&1)
expect "non-ASCII path readable" "café.txt" "$out"
out=$(cd "$s" && bash "$scope" HEAD~1..HEAD 2>&1)
expect "real range works" "mode: range" "$out"

git -C "$s" switch -q -c 'x;touch$(id)'
echo n > "$s/new.txt"; git -C "$s" add . && git -C "$s" commit -q -m three
out=$(cd "$s" && PATH="$stub:$PATH" STUB_VIEW='{"baseRefName":"main"}' bash "$scope" branch 2>&1)
expect "branch mode" "mode: branch" "$out"
reject "branch label sanitized" 'label: branch-x;' "$out"

out=$(cd "$work" && bash "$scope" 2>&1); code=$?
expect "non-git error" "not a git repository" "$out"
[ "$code" != 0 ] && pass || fail "non-git should exit non-zero"

# --- scanners
out=$(cd "$s" && bash "$scanners" relative-out 2>&1)
expect "relative outdir works" "== Done" "$out"
expect "summary is written" "== Done" "$(cat "$s/relative-out/summary.txt")"
slow="$work/slowbin"
mkdir -p "$slow"
printf '#!/bin/sh\nexec sleep 30\n' > "$slow/gitleaks"
chmod +x "$slow/gitleaks"
out=$(cd "$s" && PATH="$slow:$PATH" SCANNER_TIMEOUT=1 bash "$scanners" "$work/scan-slow" 2>&1)
expect "hung tool times out" "timedout gitleaks" "$out"
out=$(cd "$s" && touch package.json && mkdir -p node_modules/.bin &&
  printf '#!/bin/sh\necho ran > "%s/ran"\n' "$work" > node_modules/.bin/knip &&
  chmod +x node_modules/.bin/knip && bash "$scanners" "$work/scan-safe" --no-project-code 2>&1)
expect "project code skipped" "skipped  knip (--no-project-code)" "$out"
[ ! -e "$work/ran" ] && pass || fail "--no-project-code ran a project binary"

# --- install
home="$work/home"
mkdir -p "$home/.claude/skills"
out=$(HOME="$home" bash "$repo/install.sh" 2>&1); code=$?
expect "install links" "linked  audit" "$out"
[ "$code" = 0 ] && pass || fail "clean install should exit 0"
[ "$(readlink "$home/.claude/skills/audit")" = "$repo/skills/audit" ] && pass || fail "install link target"
HOME="$home" bash "$repo/install.sh" >/dev/null 2>&1 && pass || fail "re-run should exit 0"

ln -sfn /tmp/elsewhere "$home/.claude/skills/audit"
rm "$home/.claude/skills/release" && mkdir "$home/.claude/skills/release"
out=$(HOME="$home" bash "$repo/install.sh" 2>&1); code=$?
expect "foreign link kept" "already links to /tmp/elsewhere" "$out"
expect "real folder kept" "something else already exists" "$out"
[ "$code" != 0 ] && pass || fail "skips should exit non-zero"
[ "$(readlink "$home/.claude/skills/audit")" = /tmp/elsewhere ] && pass || fail "foreign link was replaced"

# --- Skills: frontmatter names match folders, and local files they name exist
for skill in "$repo"/skills/*/; do
  name=$(basename "$skill")
  grep -q "^name: $name$" "$skill/SKILL.md" && pass || fail "$name: frontmatter name"
  while IFS= read -r ref; do
    [ -e "$skill/$ref" ] && pass || fail "$name: missing $ref"
  done < <(grep -oE '\$\{CLAUDE_SKILL_DIR\}/(scripts|references)/[A-Za-z0-9._-]+' "$skill/SKILL.md" | sed 's/.*}\///' | sort -u)
done

for skill in release loop-audit improve-deterministic; do
  grep -q '^disable-model-invocation: true$' "$repo/skills/$skill/SKILL.md" && pass || fail "$skill: must be typed to run"
done

echo "$((total - failures))/$total passed"
[ "$failures" = 0 ]
