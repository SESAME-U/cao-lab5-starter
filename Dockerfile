# syntax=docker/dockerfile:1
# Lab 5, Part B: the shop image.
#
# WordPress (official image, pinned) + WooCommerce + WP-CLI + PHP upload
# settings. No password, no site data in the image: those come at run time.

ARG WORDPRESS_TAG=7.1.3-php8.4-apache

# ---------------------------------------------------------------------------
# Stage 1: fetch and unzip WooCommerce. The tools used here (wget, unzip)
# never reach the final image.
# ---------------------------------------------------------------------------
FROM alpine:3.24.2 AS plugins
ARG WOOCOMMERCE_VERSION=11.2.1
ARG WOOCOMMERCE_URL=https://downloads.wordpress.org/plugin/woocommerce.${WOOCOMMERCE_VERSION}.zip

# TODO download ${WOOCOMMERCE_URL} with wget and unzip it into /plugins
#      (one RUN instruction; you should end with /plugins/woocommerce/)

# ---------------------------------------------------------------------------
# Stage 2: the image you ship.
# ---------------------------------------------------------------------------
FROM wordpress:${WORDPRESS_TAG}
ARG WPCLI_VERSION=2.12.0

# TODO labels: org.opencontainers.image.title "cao-shop",
#      org.opencontainers.image.description, org.opencontainers.image.source
#      (the URL of your repository)

# TODO copy /plugins/woocommerce from the "plugins" stage into
#      /usr/src/wordpress/wp-content/plugins/woocommerce
#      (the official image copies /usr/src/wordpress to /var/www/html at start)

# TODO add WP-CLI ${WPCLI_VERSION} as /usr/local/bin/wp, executable:
#      https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar

# TODO copy config/uploads.ini into /usr/local/etc/php/conf.d/

# TODO HEALTHCHECK: every 10 s, timeout 3 s, start period 30 s, 3 retries,
#      curl -fsS -o /dev/null http://localhost/wp-login.php
