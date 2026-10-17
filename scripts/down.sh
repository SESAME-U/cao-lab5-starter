#!/usr/bin/env bash
# Lab 5: stop and remove the two containers and the network.
# Volumes are kept, so the shop comes back as it was with make up.
#   scripts/down.sh            containers and network only
#   scripts/down.sh --volumes  also the volumes: the database and uploads are gone
set -uo pipefail

docker rm -f shop db >/dev/null 2>&1 && echo "Containers removed." || echo "No containers to remove."
docker network rm shop-net >/dev/null 2>&1 && echo "Network shop-net removed." || true

if [[ "${1-}" == "--volumes" ]]; then
  docker volume rm db-data shop-uploads >/dev/null 2>&1 && echo "Volumes db-data and shop-uploads removed." || true
fi
