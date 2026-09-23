#!/bin/bash
set -euo pipefail

SOURCE=/usr/src/wordpress
TARGET=/app/public

fetch_salts() {
	local salts=""
	if command -v curl > /dev/null 2>&1; then
		salts="$(curl -fsSL --max-time 10 https://api.wordpress.org/secret-key/1.1/salt/ 2> /dev/null || true)"
	fi
	if [ -z "$salts" ]; then
		local keys=(AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT)
		salts=""
		for key in "${keys[@]}"; do
			salts+="define( '${key}', '$(openssl rand -base64 48 | tr -d '\n')' );"$'\n'
		done
	fi
	printf '%s' "$salts"
}

# Copy WordPress core into the persistent volume on first run
if [ ! -e "$TARGET/wp-settings.php" ]; then
	echo "WordPress core not found in $TARGET, copying from $SOURCE ..."
	mkdir -p "$TARGET"
	cp -a "$SOURCE/." "$TARGET/"
	chown -R www-data:www-data "$TARGET"
	echo "WordPress core copied."
fi

# Generate wp-config.php from environment on first run
if [ ! -e "$TARGET/wp-config.php" ]; then
	echo "Generating $TARGET/wp-config.php ..."
	salts="$(fetch_salts)"
	frankenphp php-cli /usr/local/bin/generate-wp-config.php /usr/src/wp-config.php.template "$TARGET/wp-config.php" "$salts"
	chown www-data:www-data "$TARGET/wp-config.php"
fi

# Hand over to the original FrankenPHP entrypoint (or straight to CMD)
if [ -f /usr/local/bin/entrypoint.sh ]; then
	exec /usr/local/bin/entrypoint.sh "$@"
fi
exec "$@"
