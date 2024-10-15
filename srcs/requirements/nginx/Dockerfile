# Use the penultimate stable version of Debian
FROM debian:bullseye

# Install Nginx and OpenSSL
RUN apt update && \
    apt install nginx openssl -y

# Copy Nginx configuration
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf

# Copy OpenSSL configuration
COPY ./conf/openssl.conf /etc/nginx/openssl.conf

# Generate SSL certificate
RUN mkdir /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/selfsigned.key \
    -out /etc/nginx/ssl/selfsigned.crt \
    -config /etc/nginx/openssl.conf

# Expose port 443
EXPOSE 443

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
# CMD ["nginx", "-c", "/etc/nginx/default.conf"]

