<?php
/**
 * Uninstall — leave no trace.
 *
 * Runs when the user deletes the plugin from wp-admin. Removes every option,
 * transient, scheduled event, and table the plugin creates. Users who
 * uninstall expect to be forgotten.
 *
 * @package PLExample
 */

if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit;
}

// Options.
delete_option( 'pl_example_options' );
delete_site_option( 'pl_example_options' );

// Transients seeded by the Utils helper. A direct query is intentional here:
// uninstall runs once, object caching is irrelevant, and core offers no API to
// bulk-delete transients by prefix.
global $wpdb;
// phpcs:ignore WordPress.DB.DirectDatabaseQuery.DirectQuery, WordPress.DB.DirectDatabaseQuery.NoCaching -- one-shot uninstall cleanup, see note above.
$wpdb->query(
	$wpdb->prepare(
		"DELETE FROM {$wpdb->options} WHERE option_name LIKE %s OR option_name LIKE %s",
		$wpdb->esc_like( '_transient_pl_example_' ) . '%',
		$wpdb->esc_like( '_transient_timeout_pl_example_' ) . '%'
	)
);

// Scheduled cron events would be cleared here, e.g. via
// wp_clear_scheduled_hook() under the plugin's hook prefix.
