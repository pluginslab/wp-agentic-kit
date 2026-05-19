<?php
/**
 * Tests for PLExample\Api\Rest_Hello.
 *
 * Uses the WordPress core test harness (WP_UnitTestCase). Run with:
 *   ./vendor/bin/phpunit
 *
 * @package PLExample
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use PLExample\Api\Rest_Hello;

final class Test_REST_Hello extends WP_UnitTestCase {

	public function set_up(): void {
		parent::set_up();
		( new \PLExample\Api\Rest() )->register_controllers();
		do_action( 'rest_api_init' );
	}

	public function test_get_returns_hello_payload(): void {
		$request  = new WP_REST_Request( 'GET', '/pl-example/v1/hello' );
		$response = rest_get_server()->dispatch( $request );
		$data     = $response->get_data();

		$this->assertSame( 200, $response->get_status() );
		$this->assertSame( 'Hello, World!', $data['message'] );
		$this->assertSame( PL_EXAMPLE_VERSION, $data['version'] );
	}

	public function test_response_matches_schema(): void {
		$controller = new Rest_Hello();
		$schema     = $controller->get_response_schema();

		$this->assertSame( 'object', $schema['type'] );
		$this->assertEqualSets( [ 'message', 'version' ], $schema['required'] );
		$this->assertSame( 'string', $schema['properties']['message']['type'] );
		$this->assertSame( 'string', $schema['properties']['version']['type'] );
	}

	public function test_endpoint_is_public(): void {
		// Public route should respond identically with or without a logged-in user.
		$request  = new WP_REST_Request( 'GET', '/pl-example/v1/hello' );
		$response = rest_get_server()->dispatch( $request );
		$this->assertSame( 200, $response->get_status() );

		wp_set_current_user( self::factory()->user->create() );
		$response_auth = rest_get_server()->dispatch( $request );
		$this->assertSame( 200, $response_auth->get_status() );
	}
}
