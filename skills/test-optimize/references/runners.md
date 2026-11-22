# Runner notes

How to get a report, where time usually hides, and the usual fixes, per runner. Check every option against the docs for the installed version before using it. Names change between major versions.

## Vitest

- **Report:** `vitest run --reporter=default --reporter=json --outputFile.json=<file>`. The default reporter's last lines split the time into transform, setup, collect, tests, environment, and prepare. Keep that log.
- **Coverage:** `vitest run --coverage --coverage.reporter=json-summary --coverage.reportsDirectory=<dir>` writes `<dir>/coverage-summary.json`.
- **Reading the split:** these are summed across workers, so they can exceed wall time. When environment, setup, and collect together dwarf tests, the cost is per file, not in the tests.
- **Environment:** jsdom or happy-dom costs on every file that loads it. Make `node` the default and give DOM files their own project or a `// @vitest-environment jsdom` comment. Find candidates by grepping test files for `render(`, `screen.`, `document`, `window`, and `@testing-library`.
- **Setup files:** they run once per test file. Anything heavy they import is paid by every file. Keep DOM-only setup in the DOM project.
- **Imports:** a test that imports a barrel (`index.ts` re-exporting a lot, icon sets, a whole UI kit) pays to load all of it. Import the module itself, or mock the heavy dependency when the test doesn't exercise it.
- **Pool and isolation:** `threads` usually starts faster than `forks`. `isolate: false` reuses module state across files and can be much faster, but only for files that don't mutate globals, module state, or mocks. Put those files in their own project and run them several times in shuffled order (`--sequence.shuffle`) before trusting it.
- **Waiting:** real `setTimeout`, `sleep`, polling, retries, and long `waitFor` timeouts. Use fake timers (`vi.useFakeTimers()`, `vi.advanceTimersByTime`) and `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`.
- **Typecheck:** keep `typecheck` out of the unit run. The type checker runs elsewhere.

## Jest

- **Report:** `jest --json --outputFile=<file>`. Add `--coverage --coverageReporters=json-summary` for coverage.
- **Transform:** `babel-jest` and `ts-jest` with full type checking are slow. `@swc/jest` or ts-jest with `isolatedModules` cuts transform time a lot. Type checking belongs to `tsc`.
- **Environment:** the default is `node`. A global `testEnvironment: 'jsdom'` charges every file. Use a `@jest-environment jsdom` docblock or projects.
- **Cache:** confirm `cache` isn't off and `--no-cache` isn't in the test script.
- **Workers:** `--maxWorkers=50%` is often faster than the default on laptops with efficiency cores. Measure both.
- **Module registry:** `resetModules: true` re-imports everything per test. Use it only where a test needs fresh module state.

## pytest

- **Report:** `pytest --junitxml=<file> --durations=0`. Coverage: `pytest --cov --cov-report=json:<file>`. Its JSON isn't the istanbul format, so compare per-file `summary.covered_lines` by hand or with a few lines of `jq`.
- **Fixtures:** an expensive fixture at `function` scope rebuilds for every test. Widen the scope to `module` or `session` only if no test mutates what it returns. Otherwise copy a cached template per test.
- **Parallel:** `pytest-xdist` with `-n auto`. Tests that share files, ports, or a database need per-worker names first.
- **Waiting:** `time.sleep` and real clocks. Use `freezegun` or `time-machine`, or inject the clock.
- **Collection:** `--collect-only -q` timing shows import cost. Heavy top-level imports in `conftest.py` hit every test.

## Go

- **Report:** `go test -json ./...`, or `gotestsum --junitfile <file>`. Coverage: `-coverprofile`, compared per function with `go tool cover -func`.
- **Parallel:** `t.Parallel()` in independent tests and subtests. Packages already run in parallel.
- **Cache:** `-count=1` disables the test cache. Keep it out of the everyday command.

## PHPUnit

- **Report:** `phpunit --log-junit <file>`. Coverage: `--coverage-clover`, compared per file.
- **Database:** refreshing the whole database per test is the usual cost. Use transactions rolled back per test.
- **Parallel:** ParaTest, once tests don't share state.
