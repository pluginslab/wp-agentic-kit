<?php
/**
 * Example REST endpoint: GET /wp-json/pl-example/v1/hello
 *
 * Public, read-only smoke test. Returns a greeting + the plugin version.
 * Useful for verifying activation, route registration, and the REST stack
 * before you build anything real. Remove this controller (and its line in
 * Rest::registered_controllers()) once you have real endpoints.
 *
 * @package PLExample\Api
 */

namespace PLExample\Api;

use PLExample\Utils;
use WP_REST_Request;
use WP_REST_Response;
use WP_REST_Server;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Rest_Hello {

	public function register_routes(): void {
		register_rest_route(
			Rest::NAMESPACE,
			'/hello',
			[
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => [ $this, 'get_item' ],
				'permission_callback' => '__return_true',
				'args'                => [],
				'schema'              => [ $this, 'get_response_schema' ],
			]
		);
	}

	/**
	 * Build the hello payload. Trivially small — no user input, no DB, no
	 * external calls. Anything more elaborate belongs in its own controller.
	 */
	public function get_item( WP_REST_Request $request ): WP_REST_Response {
		unset( $request );

		$payload = [
			'message' => __( 'Hello, World!', 'pl-example' ),
			'version' => Utils::version(),
		];

		return rest_ensure_response( $payload );
	}

	/**
	 * Response schema. Lets REST consumers introspect the shape and lets
	 * `Test_REST_Hello::test_response_matches_schema` catch silent drift.
	 */
	public function get_response_schema(): array {
		return [
			'$schema'    => 'http://json-schema.org/draft-04/schema#',
			'title'      => 'pl-example-hello',
			'type'       => 'object',
			'properties' => [
				'message' => [
					'type'        => 'string',
					'description' => __( 'A greeting.', 'pl-example' ),
					'context'     => [ 'view' ],
				],
				'version' => [
					'type'        => 'string',
					'description' => __( 'The installed plugin version.', 'pl-example' ),
					'context'     => [ 'view' ],
				],
			],
			'required'   => [ 'message', 'version' ],
		];
	}
}
