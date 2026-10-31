#!/usr/bin/env bash
# Offline tests for the bundled scripts. Needs only git and jq.
# Usage: tests/run.sh
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pr_state="$repo/skills/release/scripts/pr-state.sh"
scope="$repo/skills/audit/scripts/scope.sh"
scanners="$repo/skills/audit/scripts/scanners.sh"
find_personas="$repo/skills/personas/scripts/find.sh"
debate_path="$repo/skills/personas/scripts/debate-path.sh"
cleanup_scan="$repo/skills/cleanup/scripts/scan.sh"
cleanup_remove="$repo/skills/cleanup/scripts/remove.sh"
work=$(cd "$(mktemp -d)" && pwd -P)
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
  "pr list") [ -z "${STUB_PR_FAIL:-}" ] || exit 1; answer "${STUB_PRS:-[]}" ;;
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
mkdir -p "$ci/sub"
expect "CI found from a subfolder" "no checks on this commit yet" "$(state "$ci/sub" "$healthy" none 1)"
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
# gitleaks finishes only once semgrep, which starts later, has run. In order, it would time out.
together="$work/togetherbin"
mkdir -p "$together"
printf '#!/bin/sh\nuntil [ -e "%s/semgrep-ran" ]; do sleep 0.1; done\n' "$work" > "$together/gitleaks"
printf '#!/bin/sh\ntouch "%s/semgrep-ran"\n' "$work" > "$together/semgrep"
chmod +x "$together/gitleaks" "$together/semgrep"
out=$(cd "$s" && PATH="$together:$PATH" SCANNER_TIMEOUT=5 bash "$scanners" "$work/scan-together" 2>&1)
expect "tools run at the same time" "ran      gitleaks" "$out"
reject "no tool waits on another" "timedout" "$out"
expect "done comes after the tools" "== Done" "$(tail -n 1 "$work/scan-together/summary.txt")"
out=$(cd "$s" && touch package.json && mkdir -p node_modules/.bin &&
  printf '#!/bin/sh\necho ran > "%s/ran"\n' "$work" > node_modules/.bin/knip &&
  chmod +x node_modules/.bin/knip && bash "$scanners" "$work/scan-safe" --no-project-code 2>&1)
expect "project code skipped" "skipped  knip (--no-project-code)" "$out"
[ ! -e "$work/ran" ] && pass || fail "--no-project-code ran a project binary"
out=$(cd "$s" && touch requirements.txt composer.lock &&
  bash "$scanners" "$work/scan-safe-deps" --no-project-code 2>&1)
expect "pip-audit skipped" "skipped  pip-audit (--no-project-code" "$out"
expect "composer audit skipped" "skipped  composer-audit (--no-project-code" "$out"
rm -f "$s/requirements.txt" "$s/composer.lock"

# --- personas: find what a project already says
p=$(new_repo)
out=$(cd "$p" && bash "$find_personas" 2>&1); code=$?
expect "no personas" "saved: no" "$out"
[ "$code" = 0 ] && pass || fail "no personas should exit 0"
mkdir -p "$p/docs/deep" "$p/.claude/audits" "$p/.claude/agents" "$p/node_modules/x"
printf '# Rules\n\n## Personas\n- Agency owner\n' > "$p/AGENTS.md"
printf 'Our target customers are florists.\n' > "$p/docs/deep/who.md"
printf 'We never store personal data.\n' > "$p/privacy.md"
printf 'persona in the app code\n' > "$p/app.ts"
printf 'Personas walked through\n' > "$p/.claude/audits/old.md"
printf 'Added user roles\n' > "$p/CHANGELOG.md"
printf 'persona\n' > "$p/node_modules/x/README.md"
printf 'node_modules/\n' > "$p/.gitignore"
printf 'agent\n' > "$p/.claude/agents/tester.md"
out=$(cd "$p/docs" && bash "$find_personas" 2>&1)
expect "finds AGENTS.md section" "AGENTS.md:3:## Personas" "$out"
expect "finds other wording, from a subfolder" "docs/deep/who.md:1:" "$out"
expect "lists agents" "agent: .claude/agents/tester.md" "$out"
reject "personal isn't persona" "privacy.md" "$out"
reject "only docs" "app.ts" "$out"
reject "skips old reports" ".claude/audits" "$out"
reject "skips changelog" "CHANGELOG" "$out"
reject "skips ignored files" "node_modules" "$out"
printf '# Personas\n\nLast reviewed: 2026-01-02\nAlso defined in: AGENTS.md, docs/users.md\n' > "$p/.claude/personas.md"
out=$(cd "$p" && bash "$find_personas" 2>&1)
expect "saved list" "saved: yes" "$out"
expect "review date" "last_reviewed: 2026-01-02" "$out"
expect "other homes" "also_defined_in: AGENTS.md, docs/users.md" "$out"
reject "saved list isn't a match" ".claude/personas.md:" "$out"
printf '# Personas\n' > "$p/.claude/personas.md"
out=$(cd "$p" && bash "$find_personas" 2>&1)
reject "never reviewed" "last_reviewed: 2" "$out"
out=$(cd "$p" && PERSONA_MAX_MATCHES=1 bash "$find_personas" 2>&1)
expect "cut-off is reported" "stopped at 1 matches" "$out"
plain_dir="$work/not-git"
mkdir -p "$plain_dir/node_modules"
printf '## Personas\n' > "$plain_dir/notes.md"
printf 'persona\n' > "$plain_dir/node_modules/a.md"
out=$(cd "$plain_dir" && bash "$find_personas" 2>&1)
expect "works outside git" "notes.md:1:" "$out"
reject "skips dependencies outside git" "node_modules" "$out"

# --- personas: debate report paths
d=$(new_repo)
mkdir -p "$d/sub"
today=$(date +%F)
out=$(cd "$d/sub" && bash "$debate_path" 'What goes on the Pricing page?' 2>&1)
expect "debate path from a subfolder" ".claude/debates/$today-what-goes-on-the-pricing-page.md" "$out"
[ -f "$out" ] && pass || fail "debate path should be reserved"
expect "debate reports stay out of git" ".claude/debates/" "$(cat "$d/.git/info/exclude")"
out=$(cd "$d" && bash "$debate_path" 'What goes on the Pricing page?' 2>&1)
expect "debate never reuses a name" "pricing-page-2.md" "$out"
(cd "$d" && bash "$debate_path" one >/dev/null && bash "$debate_path" two >/dev/null)
[ "$(grep -cxF '.claude/debates/' "$d/.git/info/exclude")" = 1 ] && pass || fail "exclude line should appear once"
out=$(cd "$d" && bash "$debate_path" '../../etc/passwd' 2>&1)
expect "debate path can't escape" ".claude/debates/$today-etc-passwd.md" "$out"
out=$(cd "$d" && bash "$debate_path" 2>&1)
expect "debate with no topic" "$today-debate.md" "$out"
out=$(cd "$d" && bash "$debate_path" "$(printf 'x%.0s' {1..80})" 2>&1)
expect "long topic is cut" "$today-$(printf 'x%.0s' {1..50}).md" "$out"
printf '## Personas\n' > "$d/.claude/debates/old.md"
reject "find skips debates" ".claude/debates" "$(cd "$d" && bash "$find_personas" 2>&1)"
out=$(cd "$plain_dir" && bash "$debate_path" topic 2>&1)
expect "debate path works outside git" ".claude/debates/$today-topic.md" "$out"

# --- cleanup: what's safe to remove
ch="$work/cleanup-home"
app="$ch/Library/Application Support/Claude"
mkdir -p "$ch/.claude/sessions" "$app/claude-code-sessions/a/b"
scan() { (cd "$work" && HOME="$ch" PATH="$stub:$PATH" CLEANUP_RECENT_HOURS="${HOURS:-0}" bash "$cleanup_scan" --no-fetch "$@" 2>&1); }
rm_tree() { (cd "$work" && HOME="$ch" PATH="$stub:$PATH" CLEANUP_RECENT_HOURS=0 bash "$cleanup_remove" "$@" 2>&1); }
only() { scan --only "$1"; }
chat() { printf '{"sessionId":"local_%s","cwd":"%s","isArchived":%s,"lastActivityAt":%s,"title":"Old chat"}\n' \
  "$RANDOM" "$1" "$2" "$3" > "$app/claude-code-sessions/a/b/local_$RANDOM$RANDOM.json"; }

r=$(new_repo)
echo a > "$r/a.txt"; printf '.env\nnode_modules/\nkeep/\n' > "$r/.gitignore"
git -C "$r" add . && git -C "$r" commit -q -m one

# A worktree on its own new branch, with one commit when a name is given.
tree() { # <name> [file]
  git -C "$r" worktree add -q -b "$1" "$work/wt-$1"
  if [ -n "${2:-}" ]; then
    echo "$1" > "$work/wt-$1/$2"
    git -C "$work/wt-$1" add . && git -C "$work/wt-$1" commit -q -m "work on $1"
  fi
  echo "$work/wt-$1"
}

w=$(tree empty)
out=$(only "$w")
expect "merged is safe" "class: merged" "$out"
expect "ancestor reported" "merged: ancestor" "$out"
out=$(rm_tree worktree "$w")
expect "merged worktree removed" "removed: $w" "$out"
expect "merged branch deleted" "deleted_branch: empty" "$out"
[ ! -e "$w" ] && pass || fail "merged worktree should be gone"

w=$(tree squashed s.txt)
echo more >> "$w/s.txt"; git -C "$w" commit -qam "more"
git -C "$r" merge -q --squash squashed >/dev/null && git -C "$r" commit -q -m "squash"
echo c > "$r/c.txt"; git -C "$r" add . && git -C "$r" commit -q -m "later"
expect "squash merge detected" "merged: no-diff" "$(only "$w")"
expect "squash merge is safe" "class: merged" "$(only "$w")"
rm_tree worktree "$w" >/dev/null

w=$(tree picked p.txt)
git -C "$r" cherry-pick -n picked >/dev/null && git -C "$r" commit -q -m "picked again"
expect "rebased commit detected" "merged: patch" "$(only "$w")"
rm_tree worktree "$w" >/dev/null

w=$(tree open o.txt)
git -C "$r" update-ref refs/remotes/origin/pushed main
out=$(only "$w")
git -C "$r" update-ref -d refs/remotes/origin/pushed
expect "unmerged asks" "class: ask" "$out"
expect "unmerged reason" "work isn't merged" "$out"
expect "unmerged commits counted" "unique_commits: 1" "$out"
expect "local-only commits counted" "local_only_commits: 1" "$out"
out=$(rm_tree worktree "$w"); code=$?
expect "unmerged needs approval" "needs approval" "$out"
[ "$code" != 0 ] && [ -e "$w" ] && pass || fail "unmerged worktree should stay without approval"
out=$(rm_tree worktree "$w" --approved)
expect "approved removal keeps branch" "kept_branch: open" "$out"
git -C "$r" rev-parse -q --verify refs/heads/open >/dev/null && pass || fail "unmerged branch should survive"

w="$work/wt-detached"
git -C "$r" worktree add -q --detach "$w"
echo d > "$w/d.txt"; git -C "$w" add . && git -C "$w" commit -q -m "detached work"
head=$(git -C "$w" rev-parse HEAD)
out=$(rm_tree worktree "$w" --approved)
expect "detached commits rescued" "rescued: rescue/wt-detached-" "$out"
[ "$(git -C "$r" rev-parse "refs/heads/$(rescue=${head:0:8}; echo "rescue/wt-detached-$rescue")")" = "$head" ] && pass || fail "rescue branch should hold the commit"

w=$(tree dirty)
echo x > "$w/new.txt"
out=$(only "$w")
expect "merged but dirty asks" "merged, but has uncommitted changes" "$out"
out=$(rm_tree worktree "$w" --approved)
expect "dirty needs a choice" "--save-changes or --discard-changes" "$out"
out=$(rm_tree worktree "$w" --approved --save-changes)
expect "changes stashed" "stashed: cleanup: wt-dirty" "$out"
expect "stash kept" "cleanup: wt-dirty" "$(git -C "$r" stash list)"
w=$(tree dirty2)
echo x > "$w/new.txt"
out=$(rm_tree worktree "$w" --approved --discard-changes)
expect "discard removes" "removed: $w" "$out"
git -C "$r" stash clear

w=$(tree live)
printf '{"pid":%s,"cwd":"%s/sub","status":"idle"}\n' "$$" "$w" > "$ch/.claude/sessions/1.json"
out=$(only "$w")
expect "live session blocks" "class: active" "$out"
expect "live session named" "Claude session $$" "$out"
out=$(rm_tree worktree "$w" --approved --discard-changes); code=$?
[ "$code" != 0 ] && [ -e "$w" ] && pass || fail "approval must not override a live session"
printf '{"pid":999999,"cwd":"%s","status":"idle"}\n' "$w" > "$ch/.claude/sessions/1.json"
expect "dead session ignored" "class: merged" "$(only "$w")"
rm "$ch/.claude/sessions/1.json"
expect "process inside blocks" "class: active" "$(cd "$w" && HOME="$ch" CLEANUP_RECENT_HOURS=0 bash "$cleanup_scan" --no-fetch --only "$w" 2>&1)"
rm_tree worktree "$w" >/dev/null

w=$(tree chatted)
chat "$w" false 1000
out=$(only "$w")
expect "open chat asks" "merged, but its chat is still open" "$out"
expect "open chat shown" "Old chat" "$out"
rm -f "$app"/claude-code-sessions/a/b/*.json
chat "$w" true 1000
expect "archived chat ignored" "class: merged" "$(only "$w")"
rm -f "$app"/claude-code-sessions/a/b/*.json
chat "$w" false "$(($(date +%s) * 1000))"
expect "recent chat blocks" "class: active" "$(HOURS=24 only "$w")"
rm -f "$app"/claude-code-sessions/a/b/*.json
transcripts="$ch/.claude/projects/$(printf '%s' "$w" | sed 's/[^A-Za-z0-9-]/-/g')"
mkdir -p "$transcripts" && touch "$transcripts/t.jsonl"
expect "recent transcript blocks" "chat used in the last" "$(HOURS=24 only "$w")"
rm -rf "$transcripts"
expect "fresh worktree blocks" "files changed in the last" "$(HOURS=24 only "$w")"
rm_tree worktree "$w" >/dev/null

w=$(tree pooled)
printf '{"worktrees":{"p":{"path":"%s","leasedBy":null}}}' "$w" > "$app/git-worktrees.json"
expect "unleased is the app's pool" "class: pool" "$(only "$w")"
out=$(rm_tree worktree "$w" --approved); code=$?
[ "$code" != 0 ] && [ -e "$w" ] && pass || fail "pool worktrees are the app's to remove"
echo x > "$w/x.txt"
expect "pool with changes asks" "class: ask" "$(only "$w")"
rm "$w/x.txt"
printf '{"worktrees":{"p":{"path":"%s","leasedBy":"local_1"}}}' "$w" > "$app/git-worktrees.json"
expect "leased isn't the pool" "class: merged" "$(only "$w")"
rm "$app/git-worktrees.json"

git -C "$r" worktree lock "$w"
expect "locked blocks" "git has it locked" "$(only "$w")"
git -C "$r" worktree unlock "$w"

mkdir -p "$w/node_modules/x" "$w/keep"
echo s > "$w/.env"; echo n > "$w/node_modules/x/a"; echo k > "$w/keep/notes.txt"
out=$(only "$w")
expect "ignored files protect" "merged, but holds ignored files" "$out"
expect "ignored files listed" "ignored_files: 2 (.env, keep/)" "$out"
rm -rf "$w/keep"
echo s > "$r/.env"
out=$(only "$w")
expect "copies and dependencies don't count" "class: merged" "$out"
reject "no ignored list" "ignored_files" "$out"
rm_tree worktree "$w" >/dev/null

git -C "$r" remote add origin https://github.com/o/r.git
w=$(tree shipped sh.txt)
head=$(git -C "$w" rev-parse HEAD)
out=$(STUB_PRS="[{\"number\":7,\"state\":\"MERGED\",\"headRefOid\":\"$head\"}]" only "$w")
expect "merged PR counts" "merged: pr#7" "$out"
expect "merged PR is safe" "class: merged" "$out"
out=$(STUB_PRS='[{"number":7,"state":"MERGED","headRefOid":"old"}]' only "$w")
expect "commits after a PR ask" "class: ask" "$out"
expect "commits after a PR noted" "later commits" "$out"
expect "open PR shown" "pr: open #8" "$(STUB_PRS='[{"number":8,"state":"OPEN","headRefOid":"x"}]' only "$w")"
out=$(STUB_PR_FAIL=1 only "$w")
expect "gh failure asks" "class: ask" "$out"
expect "gh failure shown" "pr: unknown" "$out"
out=$(rm_tree worktree "$w" --approved --delete-branch)
expect "approved branch delete" "deleted_branch: shipped" "$out"
git -C "$r" remote remove origin

w="$work/wt-vanish"
git -C "$r" worktree add -q --detach "$w"
echo v > "$w/v.txt"; git -C "$w" add . && git -C "$w" commit -q -m "vanish"
head=$(git -C "$w" rev-parse HEAD)
rm -rf "$w"
mkdir -p "$r/.claude/worktrees/leftover"
echo l > "$r/.claude/worktrees/build.log"
git -C "$r" branch merged-one
git -C "$r" branch unmerged-one "$head"
git -C "$r" branch stale-one "$head"
git -C "$r" config branch.stale-one.remote origin
git -C "$r" config branch.stale-one.merge refs/heads/stale-one
git -C "$r" update-ref refs/remotes/origin/keep "$head"
out=$(scan "$r")
expect "missing folder is prunable" "prunable: $w $head unique_commits=1" "$out"
expect "stray file listed" "stray: $r/.claude/worktrees/build.log" "$out"
expect "stray folder listed" "stray: $r/.claude/worktrees/leftover" "$out"
expect "merged branch listed" "branch_merged: merged-one (ancestor)" "$out"
reject "main isn't a merged branch" "branch_merged: main" "$out"
expect "summary line" "summary: active=0" "$out"
out=$(rm_tree prune "$r")
expect "prune rescues commits" "rescued: rescue/wt-vanish-" "$out"
expect "prune reports" "pruned: $w" "$out"
reject "record is gone" "wt-vanish" "$(git -C "$r" worktree list)"
expect "rescued commit kept" "${head:0:7}" "$(git -C "$r" branch --contains "$head" -v)"

out=$(rm_tree branch "$r" merged-one)
expect "merged branch deleted on its own" "deleted_branch: merged-one" "$out"
out=$(rm_tree branch "$r" unmerged-one); code=$?
expect "unmerged branch needs approval" "needs approval" "$out"
[ "$code" != 0 ] && pass || fail "unmerged branch delete should fail"
expect "approved branch deleted" "deleted_branch: unmerged-one" "$(rm_tree branch "$r" unmerged-one --approved)"
expect "main is protected" "is the main branch" "$(rm_tree branch "$r" main --approved)"

expect "stray needs approval" "need approval" "$(rm_tree stray "$r/.claude/worktrees/build.log")"
expect "stray stays in the worktrees folder" "isn't under" "$(rm_tree stray "$r/a.txt" --approved)"
expect "stray can't climb out with .." "can't contain .." "$(rm_tree stray "$r/.claude/worktrees/.." --approved)"
touch "$r/.claude/worktrees/leftover/.git"
expect "stray can't be a repo" "git worktree or repo" "$(rm_tree stray "$r/.claude/worktrees/leftover" --approved)"
expect "stray removed" "removed:" "$(rm_tree stray "$r/.claude/worktrees/build.log" --approved)"

expect "main folder refused" "isn't a linked worktree" "$(rm_tree worktree "$r" --approved)"
expect "missing folder refused" "folder not found" "$(rm_tree worktree "$work/nope" --approved)"
expect "not a worktree" "not a git worktree" "$(only "$plain_dir")"
expect "bad hours rejected" "expects a number" "$(cd "$r" && HOME="$ch" CLEANUP_RECENT_HOURS=x bash "$cleanup_scan" 2>&1)"
expect "scan finds repos from chats" "repo: $r" "$(chat "$r" true 1 && cd "$work" && HOME="$ch" bash "$cleanup_scan" --no-fetch 2>&1)"
origin="$work/origin.git"
git init -q --bare -b main "$origin"
good=$(new_repo)
git -C "$good" commit -q --allow-empty -m first && git -C "$good" branch other
git -C "$good" remote add origin "$origin" && git -C "$good" push -q origin main
bad=$(new_repo)
git -C "$bad" commit -q --allow-empty -m first && git -C "$bad" branch other
git -C "$bad" remote add origin "$work/missing.git"
out=$(cd "$work" && HOME="$ch" bash "$cleanup_scan" --no-gh "$good" "$bad" 2>&1)
expect "fetch result matches its repo" "$(printf 'repo: %s\nbase: origin/main\nfetch: ok' "$good")" "$out"
expect "failed fetch matches its repo" "$(printf 'repo: %s\nbase: main\nfetch: failed' "$bad")" "$out"

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

for skill in release loop-audit improve-deterministic cleanup; do
  grep -q '^disable-model-invocation: true$' "$repo/skills/$skill/SKILL.md" && pass || fail "$skill: must be typed to run"
done
grep -q '^disable-model-invocation:' "$repo/skills/personas/SKILL.md" && fail "personas: audit must be able to invoke it" || pass

# --- Audit bundles cover every lens exactly once, and never reuse a lens id
audit_skill="$repo/skills/audit/SKILL.md"
lenses=$(grep -E '^\| [1-6] \| `' "$audit_skill" | cut -d'`' -f2 | sort)
bundle_rows=$(sed -n '/^### Bundles/,/^## /p' "$audit_skill" | grep '^| `')
bundled=$(printf '%s\n' "$bundle_rows" | cut -d'|' -f3 | grep -oE '`[a-z0-9]+`' | tr -d '`' | sort)
bundles=$(printf '%s\n' "$bundle_rows" | cut -d'`' -f2 | sort)
[ -n "$lenses" ] && [ "$lenses" = "$bundled" ] && pass || fail "bundles must cover every lens exactly once"
[ -z "$(comm -12 <(printf '%s\n' "$lenses") <(printf '%s\n' "$bundles"))" ] && pass || fail "bundle name reuses a lens id"

echo "$((total - failures))/$total passed"
[ "$failures" = 0 ]
