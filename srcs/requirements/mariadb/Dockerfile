FROM debian:bullseye

# Install MariaDB
RUN apt update && apt install mariadb-server -y && \
    rm -rf /var/lib/apt/lists/*

# Copy initialization script
COPY ./tools/init_db.sh /tools/init_db.sh
RUN chmod +x /tools/init_db.sh

# Expose MariaDB port
# EXPOSE 3306

# Set the entry point to run your script
ENTRYPOINT ["/tools/init_db.sh"]