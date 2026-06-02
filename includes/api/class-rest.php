<?php
/**
 * REST API entry point. Registers every controller listed in
 * `registered_controllers()` on the `rest_api_init` hook.
 *
 * Add a new controller by:
 *   1. Creating includes/api/class-rest-<thing>.php extending Rest_Controller.
 *   2. Appending its FQCN to the array in `registered_controllers()`.
 *
 * @package PLExample\Api
 */

namespace PLExample\Api;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Registers the plugin's REST controllers on rest_api_init.
 */
final class Rest {

	public const NAMESPACE = 'pl-example/v1';

	/**
	 * Hook controller registration onto rest_api_init.
	 */
	public function register(): void {
		add_action( 'rest_api_init', array( $this, 'register_controllers' ) );
	}

	/**
	 * Instantiate every allowlisted controller and register its routes.
	 */
	public function register_controllers(): void {
		foreach ( $this->registered_controllers() as $controller_class ) {
			( new $controller_class() )->register_routes();
		}
	}

	/**
	 * The allowlist. Adding here is the only registration point — there are
	 * no auto-discover globs, by design. One file change = one registration.
	 *
	 * @return string[] Fully-qualified class names.
	 */
	private function registered_controllers(): array {
		return array(
			Rest_Hello::class,
		);
	}
}
