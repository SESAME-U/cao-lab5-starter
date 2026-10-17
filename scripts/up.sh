#!/usr/bin/env bash
# Lab 5, Part C: start the shop as two containers.
#
#   network  shop-net       a user-defined bridge: containers find each other by name
#   volume   db-data        /var/lib/mysql of the database
#   volume   shop-uploads   /var/www/html/wp-content/uploads of the shop
#   db       mariadb:12.3.3-noble, on shop-net, no published port
#   shop     $SHOP_IMAGE, on shop-net, port $SHOP_PORT published to 80
#
# Safe to re-run: existing containers are replaced, volumes are kept.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] || { echo "Copy .env.example to .env first." >&2; exit 1; }
set -a; source .env; set +a

docker rm -f shop db >/dev/null 2>&1 || true

# TODO create the network shop-net (only if it does not exist yet)

# TODO create the volumes db-data and shop-uploads

# The official images read these variable names. Exported here, then passed
# with "-e NAME" (no value): the passwords never appear on a command line.
export MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" MARIADB_DATABASE="$DB_NAME" \
       MARIADB_USER="$DB_USER" MARIADB_PASSWORD="$DB_PASSWORD"
export WORDPRESS_DB_HOST=db WORDPRESS_DB_NAME="$DB_NAME" \
       WORDPRESS_DB_USER="$DB_USER" WORDPRESS_DB_PASSWORD="$DB_PASSWORD"

# TODO docker run the database: detached, named db, on shop-net,
#      --restart unless-stopped, the four MARIADB_* variables, db-data mounted
#      on /var/lib/mysql, a health check
#      --health-cmd "healthcheck.sh --connect --innodb_initialized" --health-interval 5s
#      image mariadb:12.3.3-noble. No -p: nobody outside the network needs it.

# TODO docker run the shop: detached, named shop, on shop-net,
#      --restart unless-stopped, the four WORDPRESS_DB_* variables,
#      -p "${SHOP_PORT}:80", shop-uploads mounted on
#      /var/www/html/wp-content/uploads, image "$SHOP_IMAGE"

echo "==> Waiting for both containers to be healthy"
for _ in $(seq 1 60); do
  db=$(docker inspect -f '{{.State.Health.Status}}' db 2>/dev/null || echo missing)
  shop=$(docker inspect -f '{{.State.Health.Status}}' shop 2>/dev/null || echo missing)
  echo "    db: $db   shop: $shop"
  [[ "$db" == healthy && "$shop" == healthy ]] && { echo "Both healthy."; exit 0; }
  sleep 3
done
echo "Not healthy after 3 minutes: docker logs db / docker logs shop" >&2
exit 1
