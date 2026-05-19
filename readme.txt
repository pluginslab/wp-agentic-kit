=== Example Plugin ===
Contributors: Example Author
Tags: agentic, scaffold, example
Requires at least: 6.7
Tested up to: 6.7
Requires PHP: 8.2
Stable tag: 0.1.0
License: MIT
License URI: https://opensource.org/licenses/MIT

An example WordPress plugin scaffolded with wp-agentic-kit. Replace this sentence with what your plugin actually does.

== Description ==

An example WordPress plugin scaffolded with wp-agentic-kit. Replace this sentence with what your plugin actually does.

The scaffold ships with one example REST endpoint at `GET /wp-json/pl-example/v1/hello` as a smoke test. Remove it once you have real endpoints (see `includes/api/class-rest-hello.php` and the matching entry in `Rest::registered_controllers()`).

== Installation ==

1. Upload the plugin folder to `/wp-content/plugins/`, or install via the wp-admin Plugins screen.
2. Activate through the Plugins menu in WordPress.
3. Visit `/wp-json/pl-example/v1/hello` to confirm the REST stack is wired up.

== Changelog ==

= 0.1.0 =
* Initial scaffold from wp-agentic-kit.
