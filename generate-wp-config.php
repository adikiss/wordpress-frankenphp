<?php

if ( PHP_SAPI !== 'cli' || 4 !== $argc ) {
	fwrite( STDERR, "Usage: generate-wp-config.php <template> <target> <salts>\n" );
	exit( 1 );
}

[ , $template, $target, $salts ] = $argv;

$map = array(
	'__DB_NAME__'      => getenv( 'WORDPRESS_DB_NAME' ) ?: 'wordpress',
	'__DB_USER__'      => getenv( 'WORDPRESS_DB_USER' ) ?: 'wordpress',
	'__DB_PASSWORD__'  => getenv( 'WORDPRESS_DB_PASSWORD' ) ?: '',
	'__DB_HOST__'      => getenv( 'WORDPRESS_DB_HOST' ) ?: 'mariadb',
	'__DB_CHARSET__'   => getenv( 'WORDPRESS_DB_CHARSET' ) ?: 'utf8mb4',
	'__DB_COLLATE__'   => getenv( 'WORDPRESS_DB_COLLATE' ) ?: '',
	'__TABLE_PREFIX__' => getenv( 'WORDPRESS_TABLE_PREFIX' ) ?: 'wp_',
	'__AUTH_KEYS__'    => $salts,
);

$contents = file_get_contents( $template );
if ( false === $contents ) {
	fwrite( STDERR, "Unable to read template: {$template}\n" );
	exit( 1 );
}

$contents = str_replace( array_keys( $map ), array_values( $map ), $contents );

if ( false === file_put_contents( $target, $contents ) ) {
	fwrite( STDERR, "Unable to write config: {$target}\n" );
	exit( 1 );
}
