# Findings — 001 example hello rest

## 2026-05-18 — `permission_callback` cannot be omitted

Confirmed via `wp-devdocs` MCP: starting with WordPress 5.5, `register_rest_route` emits a `_doing_it_wrong` notice if `permission_callback` is missing. For a public endpoint, use `__return_true` explicitly — the absence of a callback is not interpreted as "public," it's interpreted as a bug.

Impact on the plan: Step 2 explicitly sets `permission_callback` to `__return_true` rather than leaving it unset.

Reference: https://developer.wordpress.org/rest-api/extending-the-rest-api/routes-and-endpoints/#permissions-callback
