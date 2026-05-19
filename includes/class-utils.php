<?php
/**
 * Generic utilities — caching, version helpers, no business logic.
 *
 * @package PLExample
 */

namespace PLExample;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Utils {

	/**
	 * The plugin's installed version. Cached statically.
	 */
	public static function version(): string {
		return defined( 'PL_EXAMPLE_VERSION' ) ? PL_EXAMPLE_VERSION : '0.0.0';
	}

	/**
	 * Wrap a callable in a transient cache. Returns the cached value when
	 * present; otherwise computes, stores, and returns. The transient key
	 * is namespaced under the plugin slug.
	 *
	 * @param string   $key      Cache key (gets prefixed with `pl_example_`).
	 * @param int      $ttl      Seconds. Use HOUR_IN_SECONDS / DAY_IN_SECONDS.
	 * @param callable $compute  Producer when the cache misses.
	 * @return mixed
	 */
	public static function cached( string $key, int $ttl, callable $compute ) {
		$full_key = 'pl_example_' . sanitize_key( $key );
		$cached   = get_transient( $full_key );

		if ( false !== $cached ) {
			return $cached;
		}

		$value = $compute();
		set_transient( $full_key, $value, $ttl );
		return $value;
	}
}
