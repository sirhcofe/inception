#!/bin/sh

set -e

# Wait for MariaDB to be ready
# echo "Waiting for MariaDB..."
# until mysqladmin ping -h "$WORDPRESS_DB_HOST" --silent; do
#   sleep 2
# done
# echo "MariaDB is up and running."

# mariadb -h mariadb -P 3306 -u root -p abc123 

# Download WordPress if not already present
if [ ! -f wp-load.php ]; then
  echo "Downloading WordPress..."
  wp core download --allow-root
fi

# Generate wp-config.php if it doesn't exist
if [ ! -f wp-config.php ]; then
  echo "Creating wp-config.php..."
  wp config create \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$(cat /run/secrets/wp_admin_password)" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --allow-root \
    --skip-check

  # Generate authentication keys and salts
  AUTH_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
  echo "$AUTH_KEYS" >> wp-config.php
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root; then
  echo "Installing WordPress..."
  wp core install \
    --url="$WORDPRESS_SITE_URL" \
    --title="$WORDPRESS_SITE_TITLE" \
    --admin_user="$WORDPRESS_ADMIN" \
    --admin_password="$(cat /run/secrets/wp_admin_password)" \
    --admin_email="$WORDPRESS_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  # Create a regular user
  wp user create "$WORDPRESS_USER" "$WORDPRESS_USER_EMAIL" \
    --user_pass="$(cat /run/secrets/wp_user_password)" \
    --role=author \
    --allow-root

  echo "WordPress installation completed."
else
  echo "WordPress is already installed."
fi

# Adjust permissions
chown -R www-data:www-data /var/www/html

# php-fpm service uses the www.conf file to determine which port or socket to listen on
sed -i "s|^listen =.*|listen = 0.0.0.0:9000|" /etc/php/7.4/fpm/pool.d/www.conf

# Ensure required directories exist for php-fpm
mkdir -p /run/php

# Start PHP-FPM
exec "$@"
