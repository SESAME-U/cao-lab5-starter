#!/usr/bin/env bash
# Lab 5: install WordPress inside the running shop container with WP-CLI,
# then activate WooCommerce. Safe to re-run: an installed site is left alone.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

wp() { docker exec -u www-data shop wp "$@"; }

# In a Codespace the browser reaches the shop through a forwarded URL.
if [[ -n "${CODESPACE_NAME-}" ]]; then
  url="https://${CODESPACE_NAME}-${SHOP_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
  url="http://localhost:${SHOP_PORT}"
fi

echo "==> Waiting for the database connection"
for _ in $(seq 1 30); do
  wp db check >/dev/null 2>&1 && break
  sleep 2
done

if wp core is-installed >/dev/null 2>&1; then
  echo "==> WordPress already installed: nothing to do"
else
  echo "==> Installing WordPress at $url"
  wp core install --url="$url" --title="SESAME Shop" \
    --admin_user=admin --admin_password="$SHOP_ADMIN_PASSWORD" \
    --admin_email=admin@example.com --skip-email
fi

echo "==> Activating WooCommerce"
wp plugin activate woocommerce

echo
echo "Shop ready: $url  (admin / the SHOP_ADMIN_PASSWORD in your .env)"
