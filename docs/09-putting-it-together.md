# 8. Putting it together

## The scenario

You have `acme-order-tracker`, a plugin scaffolded with the kit. A stakeholder asks for a Gutenberg block that shows the status of an order, fed by a REST endpoint they can hit from anywhere.

Without the harness this is a half-day of context-switching: reading docs, copy-pasting boilerplate, remembering escape functions, fighting the block API. With the harness it's a guided pass.

Here's how each piece earns its keep on this one feature.

## 1 — Frame the work (Delegação + Descrição)

You open a Claude Code session and say:

```
> i need a gutenberg block "order-status" that shows the current status of an order,
  and a REST endpoint to fetch the status by order id. dynamic render.
```

The main agent reads `CLAUDE.md` (namespace, slug, conventions, security rules), notices a plugin already exists in the working directory, and invokes the `wordpress-feature` skill. The skill walks through its phases:

- **Phase 0 — Context.** Reads `.claude/plans/constitution.md` to confirm the needed `@wordpress/*` packages are in the defaults section, and the sanitize/escape/capability the plan will use are in the strict allowlists. They are.
- **Phase 1 — Spec.** Allocates `.claude/plans/features/003-order-status/` and writes `spec.md` — what's being built, why, acceptance bullets, an explicit `Out of scope` (no list view, no historical timeline, no notifications).
- **Phase 2 — Plan.** Writes `plan.md` with phased steps: each one names the file paths it'll touch and the test it'll write first. The Freeze assessment at the bottom: `[x]` touches security-relevant code (REST permission callback), `[x]` changes the public API surface (new REST route). Recommendation: **freeze**.

## 2 — Plan freeze (Discernimento)

The assessment recommends freeze, so the skill stops. It runs `./scripts/open-plan-pr.sh 003-order-status`, which commits `spec.md` and `plan.md` on a `plan/003-order-status` branch and opens a PR with the spec summary and plan approach pre-filled.

The agent then dispatches the `plan-reviewer` sub-agent against the PR. Read-only audit: file paths in every step ✓, `Out of scope` present ✓, no library outside the constitution ✓, tests mentioned ✓. Clean.

You review the plan PR on GitHub — five minutes, focused on whether the *approach* is right, not whether the syntax is. You merge it.

Back in the terminal, the agent pulls `main` and starts Phase 3 on a new `feat/003-order-status` branch.

## 3 — REST endpoint (Delegação via skill)

Loading `wp-rest-api` gives the main agent the controller pattern, permission-callback rules, schema conventions. It:

- Reads the plugin's main file to find the namespace and any existing controllers.
- Asks one clarifying question: *"Read-only public, or authenticated?"* You answer authenticated.
- Generates `includes/api/class-rest-order-status.php` extending `WP_REST_Controller`, with a real `permission_callback`, `sanitize_callback` on the `id` argument, and a `prepare_item_for_response` that escapes everything.
- The `post-edit.sh` hook fires after each Write call. `phpcs` runs against the new file; one warning surfaces about a docblock format. The agent fixes it.
- Reports back: route registered, two endpoints (`/orders/{id}/status` and the collection), curl smoke test passes.

## 4 — Gutenberg block (Delegação via skill)

Loading `wp-block-development` gives the main agent Block API v3 conventions and `block.json` schema. It:

- Reads `.claude/references/BLOCKS.md` for the kit's own layout conventions.
- Asks: *"You said dynamic — confirm `render.php` instead of `save.js`?"* You confirm.
- Generates `src/blocks/order-status/` with `block.json`, `index.js`, `edit.js`, `render.php`, `style.scss`, `editor.scss`.
- Validates the produced block markup via the `wp-blockmarkup` MCP.
- Runs `npm run build`, confirms output at `build/blocks/order-status/`.
- Reports back: block registered via the existing auto-register loop, no PHP changes needed beyond the build.

## 5 — Discernimento (the tests are the line)

The main agent now wants to commit. Before the commit goes through:

- The PHP file the REST controller generated has unit test scaffolding — `tests/test-rest-order-status.php`. The agent fills in tests: authenticated returns 200, unauthenticated returns 401, invalid id returns 404, valid id returns the right shape.
- `phpunit` passes. `phpcs` passes. `eslint` on `src/blocks/order-status/` passes.

If any of these had failed, the `pre-commit.sh` hook would block. The agent would see the failure on stderr and iterate.

## 6 — Diligência (the safety net)

The agent runs:

```bash
git add -A
git commit -m "feat: order-status block + REST endpoint"
```

The `pre-commit.sh` hook fires. The full quality suite runs again from scratch (defense in depth — the post-edit lint was on individual files; this one runs the whole project). Passes. Commit goes through.

The agent calls the `security-reviewer` sub-agent explicitly:

```
> have security-reviewer audit the changes
```

Read-only sub-agent reads the diff. Reports two low-severity findings (a translation string missing the text domain, and a docblock typo). Both fixed in the same session. Re-run: clean.

## 7 — Verify in WordPress (MCP)

The agent uses the `wp-playground` MCP to spin up an ephemeral WordPress instance with the plugin installed. The `chrome-devtools` MCP opens it, navigates to a page with the block inserted, screenshots it, runs Lighthouse. Everything green.

## 8 — Open the feature PR

The agent uses the `github` MCP to push the `feat/003-order-status` branch and open a PR with a description summarising what was built, links back to the merged plan PR, and the verification steps it ran. You review, merge.

After merge, the agent moves `.claude/plans/features/003-order-status/` to `.claude/plans/archive/2026-05-18-003-order-status/`. The plan is preserved as long-term agent memory; future features can reference it.

## The cost of skipping the harness

Without it, the same feature looks like:

- Re-explain the plugin's conventions on every prompt (no `CLAUDE.md`).
- Lint manually, or skip it (no hooks).
- Boilerplate every escape function call from memory (no `SECURITY.md` reference).
- Forget a `permission_callback`, ship, get a CVE (no review sub-agent).
- Lookup the block API in a browser tab (no MCP).

Each of those is small. They compound on every feature. The harness compounds the other way — the more features you ship through it, the more the conventions stick, the more the sub-agents internalize your patterns, the safer the defaults become.

## Where to go from here

- Write a sub-agent that's specific to your codebase: a "release manager," a "migration script writer," whatever you do often.
- Add an MCP for the integration you talk to weekly: Stripe, Mailchimp, your own internal API.
- Promote rules from CLAUDE.md to hooks once they've become non-negotiable.
- Amend `.claude/plans/constitution.md` as your dependency set evolves — every amendment in its own commit, with the reason in the message.

The harness is meant to evolve. The kit is the starting point.

---

← [Permissions](./08-permissions.md) · [Back to walkthrough index](./README.md)
