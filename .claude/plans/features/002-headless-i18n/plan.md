# Plan — 002-headless-i18n

## Approach

Add a `Translations` REST class that reads Polylang's `pll_get_post_language()` and `pll_get_post_translations()`, registers `language` + `translations` fields on the `post` REST type, and hooks `rest_prepare_post` to rewrite inline JSON-LD with the same translation map. All behaviour is gated behind `function_exists( 'pll_get_post_translations' )` so the plugin is a graceful no-op when Polylang is absent.

## Steps

### Step 1 — Scaffold the Translations REST class

- **Files:** `includes/api/class-translations.php` (new); `pl-example.php:46` (instantiate alongside existing `Rest`)
- **Test:** `tests/test-translations-rest.php::test_class_registers_on_rest_api_init`
- **Why:** Mirror the shape of the existing `PLExample\Api\Rest` class so the bootstrap stays uniform.

### Step 2 — Register `language` REST field on `post`

- **Files:** `includes/api/class-translations.php` (`register_language_field` method + `normalize_lang` helper, both hooked from `register()`)
- **Test:** `tests/test-translations-rest.php::test_language_field_returns_iso_code`, `::test_language_field_lowercases_polylang_output`
- **Why:** Decouple the language read from the translations map so Astro can request `_fields=id,slug,language` without paying for the sibling lookup. `normalize_lang` lowercases the raw Polylang slug so the contract holds even if a future Polylang version changes casing.

### Step 3 — Register `translations` REST field on `post`

- **Files:** `includes/api/class-translations.php` (`register_translations_field` method)
- **Test:** `tests/test-translations-rest.php::test_translations_field_returns_sibling_map`, `::test_translations_field_empty_when_no_siblings`
- **Why:** Returns `{}` (not `null`) on lone posts to keep the response shape stable for Astro's typed consumer.

### Step 4 — Add Polylang absence guard

- **Files:** `includes/api/class-translations.php` (early return in `register()` and in both field callbacks)
- **Test:** `tests/test-translations-rest.php::test_no_polylang_returns_unmodified_response`
- **Why:** Detect per-request via `function_exists`, not at activation — activation order with Polylang isn't guaranteed.

### Step 5 — Inject schema.org enrichment via `rest_prepare_post`

- **Files:** `includes/api/class-translations.php` (`filter_rest_post_content` method, hooked from `register()`); same file (`rewrite_jsonld_block` helper)
- **Test:** `tests/test-translations-rest.php::test_jsonld_in_language_added_for_blogposting`, `::test_jsonld_translation_of_work_on_secondary_language`, `::test_jsonld_work_translation_on_default_language`, `::test_jsonld_recipe_type_rewritten`, `::test_jsonld_untouched_for_product_type`, `::test_jsonld_left_alone_when_json_decode_fails`, `::test_jsonld_sibling_url_with_closing_script_tag_does_not_break_out`
- **Why:** Modify the REST payload's `content.rendered` only — never mutate stored `post_content`. JSON-LD `@type` allowlist: `BlogPosting`, `Article`, `NewsArticle`, `Recipe`. `@type` may be a string or an array per schema.org — match if any value is in the allowlist.
- **Parse strategy:** Regex-extract every `<script type="application/ld+json">…</script>` block (`/<script\s+type=["\']application\/ld\+json["\']>\s*(.+?)\s*<\/script>/is`), `json_decode` each one with assoc=true. If decode fails, leave the block untouched and continue. If it succeeds and `@type` is in the allowlist, merge `inLanguage` + `workTranslation`/`translationOfWork`, then re-encode with `wp_json_encode( $data, JSON_HEX_TAG | JSON_HEX_AMP | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE )` so a sibling URL containing `</script>` or a title containing `<` cannot break out.

### Step 6 — Document Polylang prerequisite

- **Files:**
  - `readme.txt` — add "Requires Polylang ≥ 3.x" under the standard headers
  - `CLAUDE.md` — add a new top-level "Runtime prerequisites" section noting Polylang
- **Test:** none — docs only.

### Step 7 — Version bump + changelog

- **Files:** `pl-example.php:7` (Version header); `pl-example.php:22` (`PL_EXAMPLE_VERSION`); `CHANGELOG.md` (new `## [0.2.0]` entry)

## Risks / open questions

- **Multiple JSON-LD blocks per post.** Rewrite every block whose top-level `@type` matches the allowlist; leave others (e.g. `ItemList`, `BreadcrumbList`) alone.
- **Caching.** `rest_prepare_post` runs per request; the JSON-LD rewrite is a small regex + decode/encode pass. Don't add a transient layer in this feature — measure first.
- **Custom field shape over `_links`.** WP REST convention for related resources is the HAL-style `_links` / `_embedded` envelope. We're using a flat `translations: { lang: { id, slug, url } }` map instead because Astro's typed consumer benefits from a stable, indexable shape and the relation is small (~5 fields). To be noted in `findings.md` once implementation starts so future readers see the deviation was deliberate.
- **Recipe schema.** Allowlist now includes `Recipe` because the consumer is kitchen.marcelschmitz.com. Other types (`Product`, `FAQPage`, `HowTo`) intentionally excluded — add later only if a real post needs it.

## Freeze assessment

Mark every box that applies. Any one yes → recommend plan freeze.

- [x] Touches security-relevant code (REST field registration + content rewrite on REST responses).
- [ ] Adds a new dependency (npm or Composer) outside the constitution's defaults. Polylang is a host-side runtime dep, not a Composer/npm package.
- [ ] Modifies database schema.
- [x] Changes the public API surface (new `language` + `translations` REST fields on `post`).
- [ ] Cross-cuts more than 3 files.

**Recommendation:** freeze
**Reason:** Public REST shape change plus content rewriting deserves a human pass on the field names, the JSON-LD `@type` allowlist, and the original-vs-translation direction convention before code lands.
