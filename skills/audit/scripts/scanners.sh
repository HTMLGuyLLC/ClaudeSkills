#!/usr/bin/env bash
# Runs whichever audit tools are already installed, saving each result to <outdir>.
# Tools run at the same time, so "ran" lines come in the order they finish.
# Installs nothing, but some tools contact their own advisory services or rule registries.
# Usage: scanners.sh <outdir> [--no-project-code]
# --no-project-code skips anything a repo can control (project binaries and yarn).
# Use it for code the user didn't write. A missing "Done" line means the run was cut off.
set -uo pipefail

out=${1:?usage: scanners.sh <outdir> [--no-project-code]}
no_project_code=
[ "${2:-}" != --no-project-code ] || no_project_code=1
limit=${SCANNER_TIMEOUT:-90}

mkdir -p "$out" || exit 1
out=$(cd "$out" && pwd) || exit 1
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

summary="$out/summary.txt"
: > "$summary"
note() { printf '%s\n' "$*" | tee -a "$summary"; }

# run <name> <command...>: starts the tool in the background. Audit tools exit
# non-zero when they find issues, so that isn't a failure.
run() {
  local name=$1; shift
  note "started  $name"
  (
    if command -v perl >/dev/null 2>&1; then
      perl -e 'alarm shift; exec @ARGV or exit 127' "$limit" "$@" < /dev/null > "$out/$name.txt" 2>&1
    else
      "$@" < /dev/null > "$out/$name.txt" 2>&1
    fi
    code=$?
    if [ "$code" = 142 ]; then
      note "timedout $name after ${limit}s, so treat its checks as Not verified"
    else
      note "ran      $name (exit $code, $(wc -l < "$out/$name.txt" | tr -d ' ') lines): $out/$name.txt"
    fi
  ) &
}

# tool <name> <install hint> <command...>: runs only if the command exists.
tool() {
  local name=$1 hint=$2; shift 2
  if command -v "$1" >/dev/null 2>&1; then run "$name" "$@"; else note "skipped  $name (install: $hint)"; fi
}

# local_bin <name> <install hint> <bin> <args...>: project-installed node tools only, so npx can't download.
local_bin() {
  local name=$1 hint=$2 bin=$3; shift 3
  if [ -n "$no_project_code" ]; then
    note "skipped  $name (--no-project-code)"
  elif [ -x "node_modules/.bin/$bin" ]; then
    run "$name" "node_modules/.bin/$bin" "$@"
  else
    note "skipped  $name (install: $hint)"
  fi
}

note "== Dependencies =="
found_manifest=
if [ -f package.json ]; then
  found_manifest=1
  if [ -f pnpm-lock.yaml ]; then
    tool pnpm-audit "pnpm" pnpm audit
    tool pnpm-outdated "pnpm" pnpm outdated
  elif [ -f yarn.lock ]; then
    if [ -n "$no_project_code" ]; then
      note "skipped  yarn-audit and yarn-outdated (--no-project-code; a repo's .yarnrc can choose the yarn binary)"
    else
      tool yarn-audit "yarn" yarn audit
      tool yarn-outdated "yarn" yarn outdated
    fi
  elif [ -f bun.lock ] || [ -f bun.lockb ]; then
    tool bun-audit "bun" bun audit
    tool bun-outdated "bun" bun outdated
  elif [ -f package-lock.json ]; then
    tool npm-audit "npm" npm audit
    tool npm-outdated "npm" npm outdated
  else
    note "skipped  npm-audit (no lockfile, which is a finding for apps)"
    tool npm-outdated "npm" npm outdated
  fi
fi
if [ -f requirements.txt ] || [ -f pyproject.toml ]; then
  found_manifest=1
  if [ -n "$no_project_code" ]; then
    note "skipped  pip-audit (--no-project-code; it can run the project's build code)"
  elif [ -f requirements.txt ]; then
    tool pip-audit "pipx install pip-audit" pip-audit -r requirements.txt
  else
    tool pip-audit "pipx install pip-audit" pip-audit .
  fi
fi
if [ -f Cargo.toml ]; then
  found_manifest=1
  # Both take cargo's lock, so a waiting tool could use up its time limit.
  if cargo audit --version >/dev/null 2>&1; then run cargo-audit cargo audit; wait; else note "skipped  cargo-audit (install: cargo install cargo-audit)"; fi
  if cargo outdated --version >/dev/null 2>&1; then run cargo-outdated cargo outdated --root-deps-only; else note "skipped  cargo-outdated (install: cargo install cargo-outdated)"; fi
fi
if [ -f go.mod ]; then
  found_manifest=1
  tool govulncheck "go install golang.org/x/vuln/cmd/govulncheck@latest" govulncheck ./...
  tool go-outdated "go" go list -u -m all
fi
if [ -f Gemfile.lock ]; then
  found_manifest=1
  tool bundle-audit "gem install bundler-audit" bundle-audit check --update
fi
if [ -f composer.lock ]; then
  found_manifest=1
  if [ -n "$no_project_code" ]; then
    note "skipped  composer-audit (--no-project-code; it can load the project's plugins)"
  else
    tool composer-audit "composer" composer audit
  fi
fi
[ -n "$found_manifest" ] || note "no supported manifest at the root (npm, Python, Rust, Go, Ruby, PHP); check dependencies by hand if the project has any"

note "== Security =="
tool gitleaks "brew install gitleaks" gitleaks dir . --redact --no-banner
if git rev-parse --git-dir >/dev/null 2>&1; then
  tool gitleaks-history "brew install gitleaks" gitleaks git . --redact --no-banner
fi
tool osv-scanner "brew install osv-scanner" osv-scanner scan source -r .
tool semgrep "brew install semgrep" semgrep scan --config p/default --metrics=off --quiet

note "== Code quality =="
shell_files=()
while IFS= read -r -d '' file; do shell_files+=("$file"); done < <(git ls-files -z '*.sh' '*.bash' 2>/dev/null)
if [ ${#shell_files[@]} -gt 0 ]; then
  tool shellcheck "brew install shellcheck" shellcheck -f gcc "${shell_files[@]}"
fi
if [ -f package.json ]; then
  local_bin knip "npm i -D knip" knip --no-exit-code
  local_bin jscpd "npm i -D jscpd" jscpd . --silent --ignore "**/node_modules/**,**/dist/**,**/build/**,**/.next/**"
fi

wait
note "== Done. Full output is in $out =="
