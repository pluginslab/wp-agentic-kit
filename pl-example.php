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
 * Autoload the plugin's own classes from includes/ using WordPress-style
 * filenames (PLExample\Api\Rest_Hello => includes/api/class-rest-hello.php).
 *
 * Composer's vendor autoloader (required above) handles third-party packages
 * and an optimized classmap of existing files. This resolver covers the
 * plugin's first-party classes and, unlike a classmap, finds new files the
 * moment you add them — no `composer dump-autoload` step.
 *
 * @param string $class Fully-qualified class name being loaded.
 */
spl_autoload_register(
	static function ( string $class ): void {
		$prefix = 'PLExample\\';
		if ( 0 !== strncmp( $class, $prefix, strlen( $prefix ) ) ) {
			return;
		}
		$parts      = explode( '\\', substr( $class, strlen( $prefix ) ) );
		$class_name = array_pop( $parts );
		$subdir     = $parts ? strtolower( implode( '/', $parts ) ) . '/' : '';
		$file       = PL_EXAMPLE_PATH . 'includes/' . $subdir . 'class-' . strtolower( str_replace( '_', '-', $class_name ) ) . '.php';
		if ( is_readable( $file ) ) {
			require_once $file;
		}
	}
);

/**
 * Bootstrap. Single instance, hooks wired here and nowhere else.
 */
final class PL_Example_Plugin {

	/**
	 * The single shared instance.
	 *
	 * @var self|null
	 */
	private static ?self $instance = null;

	/**
	 * Return the shared instance, creating it on first call.
	 *
	 * @return self
	 */
	public static function get_instance(): self {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	/**
	 * Wire the plugin's hooks. The only place hooks are registered.
	 */
	private function __construct() {
		add_action( 'init', array( $this, 'load_textdomain' ) );
		( new PLExample\Api\Rest() )->register();
	}

	/**
	 * Load the plugin text domain for translations.
	 */
	public function load_textdomain(): void {
		load_plugin_textdomain( 'pl-example', false, dirname( plugin_basename( __FILE__ ) ) . '/languages' );
	}
}

register_activation_hook( __FILE__, array( 'PL_Example_Plugin', 'get_instance' ) );

add_action( 'plugins_loaded', array( 'PL_Example_Plugin', 'get_instance' ) );
