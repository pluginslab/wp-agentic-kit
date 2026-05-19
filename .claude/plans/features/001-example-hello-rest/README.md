# Example feature

This directory ships with the wp-agentic-kit scaffold as a worked example of a feature that has **actually shipped**. Every file referenced in `plan.md` exists in the scaffold:

- `pl-example.php` — bootstrap that wires the REST controller
- `includes/api/class-rest.php` — REST base + allowlist of controllers
- `includes/api/class-rest-hello.php` — the example endpoint itself
- `tests/phpunit/test-rest-hello.php` — PHPUnit fixture

Read the plan files in order — `spec.md`, `plan.md`, `findings.md`, `progress.md` — to see how a real feature flows through the kit. Then read the code they reference to see what the agent's output looks like in practice. Use both as a template for your own first feature.

## When you're ready to start real work

Either delete this directory:

```bash
rm -rf .claude/plans/features/001-example-hello-rest
```

Or move it to the archive to keep it as a long-term reference:

```bash
mv .claude/plans/features/001-example-hello-rest \
   .claude/plans/archive/2026-05-18-001-example-hello-rest
```

The `progress.md` here has `status: complete`, so the `user-prompt-submit.sh` hook won't treat it as an active feature — it stays out of your way either way.

## Why it ships with `status: complete`

A "complete" example shows the full lifecycle of a feature plan: spec, plan, findings, progress entries, archive intent. An "in_progress" example would leave the new plugin permanently in a half-implemented state, which is worse than no example at all.
