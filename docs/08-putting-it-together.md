# 8. Putting it together

## The scenario

You have `acme-order-tracker`, a plugin scaffolded with the kit. A stakeholder asks for a Gutenberg block that shows the status of an order, fed by a REST endpoint they can hit from anywhere.

Without the harness this is a half-day of context-switching: reading docs, copy-pasting boilerplate, remembering escape functions, fighting the block API. With the harness it's a guided pass.

Here's how each piece earns its keep on this one feature.

## 1 — Frame the work (Delegação)

You open a Claude Code session and say:

```
> i need a gutenberg block "order-status" that shows the current status of an order,
  and a REST endpoint to fetch the status by order id. dynamic render. use the
  block-builder and rest-builder sub-agents.
```

The main agent reads `CLAUDE.md` (so it knows the namespace, slug, conventions, security rules) and breaks the task into two: a block and an endpoint. It hands off to the specialist sub-agents in parallel.

## 2 — REST endpoint (Descrição via skill + sub-agent)

`rest-endpoint-builder` runs. It:

- Reads the plugin's main file to find the namespace and existing controllers.
- Asks one clarifying question: *"Read-only public, or authenticated?"* You answer authenticated.
- Generates `includes/api/class-rest-order-status.php` extending `WP_REST_Controller`, with a real `permission_callback`, `sanitize_callback` on the `id` argument, and a `prepare_item_for_response` that escapes everything.
- The `post-edit.sh` hook fires after each Write call. `phpcs` runs against the new file; one warning surfaces about a docblock format. The sub-agent fixes it.
- Sub-agent reports back: route registered, two endpoints (`/orders/{id}/status` and the collection), curl smoke test passes.

## 3 — Gutenberg block (Descrição via skill + sub-agent)

`gutenberg-block-builder` runs in parallel. It:

- Reads `.claude/skills/wordpress-development/references/BLOCKS.md` for the layout convention.
- Asks: *"You said dynamic — confirm `render.php` instead of `save.js`?"* You confirm.
- Generates `src/blocks/order-status/` with `block.json`, `index.js`, `edit.js`, `render.php`, `style.scss`, `editor.scss`.
- Validates the produced block markup via the `wp-blockmarkup` MCP.
- Runs `npm run build`, confirms output at `build/blocks/order-status/`.
- Sub-agent reports back: block registered via the existing auto-register loop, no PHP changes needed beyond the build.

## 4 — Discernimento (the tests are the line)

The main agent now wants to commit. Before the commit goes through:

- The PHP file the REST controller generated has unit test scaffolding — `tests/test-rest-order-status.php`. The agent fills in tests: authenticated returns 200, unauthenticated returns 401, invalid id returns 404, valid id returns the right shape.
- `phpunit` passes. `phpcs` passes. `eslint` on `src/blocks/order-status/` passes.

If any of these had failed, the `pre-commit.sh` hook would block. The agent would see the failure on stderr and iterate.

## 5 — Diligência (the safety net)

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

## 6 — Verify in WordPress (MCP)

The agent uses the `wp-playground` MCP to spin up an ephemeral WordPress instance with the plugin installed. The `chrome-devtools` MCP opens it, navigates to a page with the block inserted, screenshots it, runs Lighthouse. Everything green.

## 7 — Open the PR

The agent uses the `github` MCP to push the branch and open a PR with a description summarising what was built and the verification steps it ran. You review the PR in the browser, merge.

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
- Start a `CHANGELOG.md` to track decisions across sessions.

The harness is meant to evolve. The kit is the starting point.

---

← [Permissions](./07-permissions.md) · [Back to walkthrough index](./README.md)
