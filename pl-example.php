<?php
/**
 * Plugin Name:       Example Plugin
 * Plugin URI:        https://example.com/pl-example
 * Description:       An example WordPress plugin scaffolded with wp-agentic-kit. Replace this sentence with what your plugin actually does.
 * Version:           0.1.0
 * Requires at least: 6.7
 * Requires PHP:      8.2
 * Author:            Example Author
 * License:           MIT
 * License URI:       https://opensource.org/licenses/MIT
 * Text Domain:       pl-example
 * Domain Path:       /languages
 *
 * @package PLExample
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'PL_EXAMPLE_VERSION', '0.1.0' );
define( 'PL_EXAMPLE_FILE', __FILE__ );
define( 'PL_EXAMPLE_PATH', plugin_dir_path( __FILE__ ) );
define( 'PL_EXAMPLE_URL', plugin_dir_url( __FILE__ ) );

require_once PL_EXAMPLE_PATH . 'vendor/autoload.php';

/**
 * Bootstrap. Single instance, hooks wired here and nowhere else.
 */
final class PL_Example_Plugin {

	private static ?self $instance = null;

	public static function get_instance(): self {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	private function __construct() {
		add_action( 'init', [ $this, 'load_textdomain' ] );
		( new PLExample\Api\Rest() )->register();
	}

	public function load_textdomain(): void {
		load_plugin_textdomain( 'pl-example', false, dirname( plugin_basename( __FILE__ ) ) . '/languages' );
	}
}

register_activation_hook( __FILE__, [ 'PL_Example_Plugin', 'get_instance' ] );

add_action( 'plugins_loaded', [ 'PL_Example_Plugin', 'get_instance' ] );
