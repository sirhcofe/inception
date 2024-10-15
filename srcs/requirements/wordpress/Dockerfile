# Use the penultimate stable version of Debian
FROM debian:bullseye

# Install dependencies
RUN apt update && apt install \
    bash \
    mariadb-client \
	mariadb-server \
    php \
	php-fpm \
	php-mysql \
    curl -y

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Set working directory
WORKDIR /var/www/html

# Copy entrypoint script
COPY ./tools/entrypoint.sh /tools/
RUN chmod +x /tools/entrypoint.sh

# Expose PHP-FPM port
EXPOSE 9000

# Use custom entrypoint script
ENTRYPOINT ["/tools/entrypoint.sh"]

# Start php-fpm
CMD ["php-fpm7.4", "-F"]
