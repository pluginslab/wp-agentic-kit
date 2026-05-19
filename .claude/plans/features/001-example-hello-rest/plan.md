# Plan — 001 example hello rest

## Approach

Extend the existing REST controller base in `includes/api/class-rest.php` with a new `class-rest-hello.php` that registers a single read-only route. The auto-loader in the bootstrap picks it up; no changes needed in `pl-example.php`. PHPUnit fixture exercises the route via the WP_REST_Request stack.

## Steps

### Step 1 — Write the PHPUnit fixture

- **Files:** `tests/phpunit/test-rest-hello.php` (new)
- **Test:** `Test_REST_Hello::test_get_returns_hello_payload`
- **Why:** test-first locks the response shape before the implementation can drift from it.

### Step 2 — Implement the controller

- **Files:** `includes/api/class-rest-hello.php` (new), `includes/api/class-rest.php::registered_controllers()` (add `Rest_Hello::class`)
- **Test:** existing fixture from Step 1 now passes.
- **Why:** the auto-load array is the single registration point; adding a class there is the only bootstrap change.

### Step 3 — Verify the response schema

- **Files:** `includes/api/class-rest-hello.php::get_response_schema()`
- **Test:** `Test_REST_Hello::test_response_matches_schema`
- **Why:** schema validation catches silent shape changes when other code touches the controller later.

### Step 4 — Smoke test against a live WordPress

- **Files:** none — verification only
- **Test:** `curl http://localhost:8888/wp-json/pl-example/v1/hello` via `wp-env` returns 200 with the expected JSON.

## Risks / open questions

- None — this is a trivial example. Real features would name dependencies on existing schemas, expected race conditions, or rollback strategy here.
