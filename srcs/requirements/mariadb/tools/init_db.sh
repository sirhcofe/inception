#!/bin/sh

set -e

# Function to check if MariaDB is up and running
check_mariadb() {
    mariadb-admin ping --silent --user=root --password="$DB_ROOT_PASSWORD"
}

# Set root password from secret
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Set WordPress user password from secret
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)

# Check if the database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting MariaDB server..."
    mysqld_safe --datadir=/var/lib/mysql &
    MYSQLD_PID=$!

    # Wait for MariaDB to start
    echo "Waiting for MariaDB to be ready..."
    until mariadb-admin ping --silent; do
        sleep 1
    done

    echo "Securing MariaDB and setting up initial database..."

    # Secure installation and create database and users
    mariadb -u root << EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;

-- Reload privilege tables
FLUSH PRIVILEGES;

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create WordPress user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${WP_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down MariaDB after initial setup..."
    mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown

    wait "${MYSQLD_PID}"

    echo "MariaDB initialization completed."
else
    echo "MariaDB data directory already exists. Skipping initialization."
fi

echo "listening to 0.0.0.0"
sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf 

echo "Starting MariaDB in foreground..."
exec mysqld_safe --datadir=/var/lib/mysql
