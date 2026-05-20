# Spec — 002-headless-i18n

## What

A companion to Polylang that exposes per-post translation siblings on the WP REST API for a headless consumer (Astro at kitchen.marcelschmitz.com). Every `post` returned by `/wp/v2/posts` gains a `language` field (ISO code) and a `translations` map ({ lang_code: { id, slug, url } }) describing sibling posts. The plugin additionally enriches schema.org JSON-LD that the editor has placed inside `post_content` with `inLanguage` and `workTranslation` / `translationOfWork` references, computed from the same translation map. No frontend rendering, no admin UI — purely a REST-shape change.

## Why

Astro builds `/blog/{lang}/{slug}` routes from WP and renders a "Read in Portuguese" switcher on each post. Polylang's free tier provides the wp-admin UX to mark posts as translations of each other, but its REST output does not include a structured sibling map and does not propagate language metadata into schema.org. Without those two pieces, Astro can't link translations and SEO loses hreflang-equivalent signals on the JSON-LD layer.

## Acceptance

- Every `post` REST response includes `language` (lowercase ISO 639-1, e.g. `"en"`, `"pt"`) and `translations` ({ `lang`: { `id`, `slug`, `url` } }) — empty object when the post has no siblings. Whatever `pll_get_post_language()` returns is normalized to lowercase before serialization.
- When at least one sibling exists, every `<script type="application/ld+json">` block in `post_content` whose top-level `@type` is `BlogPosting`, `Article`, `NewsArticle`, or `Recipe` is rewritten in the REST payload to include `inLanguage` (post's code) and either `workTranslation` (on posts in Polylang's default language) or `translationOfWork` (on posts in any other language) referencing sibling URLs. Re-emitted JSON uses `JSON_HEX_TAG | JSON_HEX_AMP | JSON_UNESCAPED_SLASHES` so a sibling URL or title containing `</script>` cannot break the script tag.
- Direction convention: a post in the Polylang default language is treated as the original (`workTranslation` array of siblings); a post in any other language is treated as a translation (`translationOfWork` referencing the default-language sibling, falling back to the first available sibling if no default-language sibling exists).
- When Polylang functions are not available, `language` and `translations` fields are absent and `post_content` is returned untouched.
- The plugin ships zero admin UI and zero options; behaviour is wholly determined by Polylang state.
- `./scripts/quality.sh` passes (phpcs + phpunit).

## Out of scope

- Translating UI strings of this plugin itself (no `.pot` / `wp_set_script_translations` pipeline).
- Translating taxonomies, terms, menus, or custom post types — only the built-in `post` type.
- Bundling, installing, or auto-activating Polylang. It's a documented runtime prerequisite.
- Astro-side routing, build, or component code.
- Generating schema.org for posts that do not already contain an inline `<script type="application/ld+json">`.
- A language switcher UI inside wp-admin (Polylang's own switcher is enough for the single editor).
- Multilingual REST permissions, per-language auth, or per-language draft visibility.
- Migration tooling for posts authored before Polylang was installed.
