# tests/

Tests for the kit itself. Plain bash, zero external dependencies.

The kit ships behaviour the user is supposed to trust (hooks, scripts, MCP wiring). Anything trustable should be testable, and anything testable should have a test pinned to it.

## Run

```bash
./tests/run.sh              # everything
./tests/run.sh hooks        # just one layer
./tests/run.sh hooks/test-stop.sh   # one file
```

Returns non-zero if any test failed. Integrates into `scripts/quality.sh` so a failing test blocks commits via the `pre-commit.sh` hook.

## Layout

```
tests/
├── README.md
├── lib.sh                  # shared helpers (assertions, sandbox, run_hook)
├── run.sh                  # entry point — discovers and runs everything
└── hooks/                  # Layer 1: per-hook behaviour
    ├── test-user-prompt-submit.sh
    ├── test-stop.sh
    ├── test-post-edit.sh
    └── test-pre-commit.sh
```

Future layers slot in as sibling directories (`tests/structure/`, `tests/cli/`, …) without touching the runner.

## How tests work

Each `test-*.sh` file:

1. Sources `tests/lib.sh` for assertions and sandbox helpers.
2. Prints the name of the unit under test.
3. Runs each case as `setup_sandbox` → fixture writes → `run_hook` → assertions → `teardown_sandbox`.
4. Exits with `$FAIL_COUNT` so the runner can tally.

The sandbox is a temp dir made fresh per case (so tests don't leak state) with a mini `.claude/plans/` skeleton already in place.

## Adding a test

1. Drop a `test-<name>.sh` under `tests/hooks/` (or a new layer dir).
2. Source `lib.sh`. Use the existing helpers: `setup_sandbox`, `write_progress`, `run_hook`, `assert_*`.
3. Make it executable (`chmod +x`).
4. Run it directly first (`./tests/hooks/test-foo.sh`), then via the runner.

## Test conventions

- **One assertion per case, narrowly scoped.** `assert_contains "in_progress → mentions slug" "$out" "001-foo"` beats one giant assert per case.
- **Setup is fast.** No network, no real WordPress, no Docker. If a test needs Playground, it lives in a different layer that's opt-in.
- **Tests fail-loud.** Red `✗` lines name what failed and what was expected vs. seen.
- **No hidden dependencies.** Tests must run on a fresh checkout with nothing installed except bash + coreutils. Linters being absent should be tested explicitly (the "no phpcs installed" cases in `test-post-edit.sh` are deliberate).

## Why bash, why now

The kit's load-bearing pieces — the four hooks — are bash. The simplest, lowest-friction tests for bash are more bash. Bats / shellspec / shunit2 are all fine; they're also another dependency a fresh scaffold has to install. We pay zero install cost this way, and the test runner itself is 60 lines anyone can read.

When the test suite grows past what bare bash comfortably handles, the conversation to add a real runner can happen with evidence.
