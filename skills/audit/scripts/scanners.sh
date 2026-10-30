#!/usr/bin/env bash
# Runs whichever audit tools are already installed, saving each result to <outdir>.
# Downloads nothing and never runs project scripts.
# Usage: scanners.sh <outdir>
set -uo pipefail

out=${1:?usage: scanners.sh <outdir>}
mkdir -p "$out"
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

summary="$out/summary.txt"
: > "$summary"
note() { printf '%s\n' "$*" | tee -a "$summary"; }

# run <name> <command...>: audit tools exit non-zero when they find issues, so that isn't a failure.
run() {
  local name=$1; shift
  "$@" > "$out/$name.txt" 2>&1
  local code=$?
  note "ran      $name (exit $code, $(wc -l < "$out/$name.txt" | tr -d ' ') lines): $out/$name.txt"
}

# tool <name> <install hint> <command...>: runs only if the command exists.
tool() {
  local name=$1 hint=$2; shift 2
  if command -v "$1" >/dev/null 2>&1; then run "$name" "$@"; else note "skipped  $name (install: $hint)"; fi
}

# local_bin <name> <install hint> <bin> <args...>: project-installed node tools only, so npx can't download.
local_bin() {
  local name=$1 hint=$2 bin=$3; shift 3
  if [ -x "node_modules/.bin/$bin" ]; then run "$name" "node_modules/.bin/$bin" "$@"; else note "skipped  $name (install: $hint)"; fi
}

note "== Dependencies =="
found_manifest=
if [ -f package.json ]; then
  found_manifest=1
  if [ -f pnpm-lock.yaml ]; then
    tool pnpm-audit "pnpm" pnpm audit
    tool pnpm-outdated "pnpm" pnpm outdated
  elif [ -f yarn.lock ]; then
    tool yarn-audit "yarn" yarn audit
    tool yarn-outdated "yarn" yarn outdated
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
  tool pip-audit "pipx install pip-audit" pip-audit
fi
if [ -f Cargo.toml ]; then
  found_manifest=1
  if cargo audit --version >/dev/null 2>&1; then run cargo-audit cargo audit; else note "skipped  cargo-audit (install: cargo install cargo-audit)"; fi
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
  tool composer-audit "composer" composer audit
fi
[ -n "$found_manifest" ] || note "no root manifest found; check subfolders in a monorepo"

note "== Security =="
tool gitleaks "brew install gitleaks" gitleaks dir . --redact --no-banner
tool osv-scanner "brew install osv-scanner" osv-scanner scan source -r .
tool semgrep "brew install semgrep" semgrep scan --config p/default --metrics=off --quiet

note "== Code quality =="
if [ -f package.json ]; then
  local_bin knip "npm i -D knip" knip --no-exit-code
  local_bin jscpd "npm i -D jscpd" jscpd . --silent --ignore "**/node_modules/**,**/dist/**,**/build/**,**/.next/**"
fi

note "== Done. Full output is in $out =="
