# Spec — 001 example hello rest

<!--
This is an example feature shipped with the wp-agentic-kit scaffold. It
demonstrates what the four plan files look like for a feature that has
already shipped. Delete this dir (or move it to .claude/plans/archive/)
before you start your first real feature.
-->

## What

A read-only REST endpoint at `GET /wp-json/pl-example/v1/hello` that returns a JSON payload with a greeting message and the plugin version. Used to smoke-test the plugin's API surface — handy in development, removable once your real endpoints exist.

## Why

Every new plugin scaffolded with wp-agentic-kit needs a way to confirm the REST controller wiring is working end to end. A trivial endpoint gives you one curl command to verify activation, route registration, and permission callbacks before you build anything real.

## Acceptance

- `GET /wp-json/pl-example/v1/hello` returns HTTP 200 with `{ message: "Hello, World!", version: "<plugin version>" }`.
- Endpoint is public (no authentication) — `permission_callback` returns `true` for `read` capability, which all logged-out users have via `__return_true`.
- PHPUnit test exercises both the happy path and the response schema.
- The endpoint registers via the existing REST controller auto-load — no new bootstrap changes needed.

## Out of scope

- No POST / PUT / DELETE methods. Read-only by design.
- No internationalization of the message string in this example (production endpoints would use `__()`).
- No rate limiting or caching headers. This is a smoke-test endpoint, not a public API.
- No frontend block consuming the endpoint. That belongs in a separate feature.
