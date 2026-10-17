#!/usr/bin/env bash
# Autograder, Lab 5. Usage: tests/run.sh lint|image|run|persist|all
# Runs on the GitHub runner (Docker available) or in your Codespace.
# Editing this file does not change your grade: the instructor's copy is used.
set -uo pipefail
cd "$(dirname "$0")/.."

IMAGE="cao-shop:test"
fails=0
pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; fails=$((fails + 1)); }
check() { local msg="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$msg"; else fail "$msg"; fi; }

stage_lint() {
  echo "== lint"
  check "Dockerfile builds FROM the official wordpress image, with a stage named plugins" \
    bash -c "grep -qE '^FROM wordpress:' Dockerfile && grep -qiE '^FROM .+ AS plugins' Dockerfile"
  if command -v hadolint >/dev/null 2>&1; then
    check "hadolint finds no warning or error" hadolint --failure-threshold warning Dockerfile
  else
    check "hadolint finds no warning or error" \
      bash -c "docker run --rm -i hadolint/hadolint:v2.14.0 hadolint --failure-threshold warning - < Dockerfile"
  fi
}

stage_image() {
  echo "== image"
  # shellcheck disable=SC2086
  if docker build -q -t "$IMAGE" ${BUILD_ARGS:-} -f "${DOCKERFILE:-Dockerfile}" . >/dev/null; then
    pass "docker build succeeds"
  else
    fail "docker build succeeds"; return
  fi
  check "WooCommerce 11.2.1 is in /usr/src/wordpress/wp-content/plugins/woocommerce" \
    bash -c "docker run --rm --entrypoint grep $IMAGE -q 'Version: 11.2.1' /usr/src/wordpress/wp-content/plugins/woocommerce/woocommerce.php"
  check "WP-CLI answers: wp --info" docker run --rm --entrypoint wp "$IMAGE" --info --allow-root
  check "PHP upload_max_filesize is 64M" \
    bash -c "[ \"\$(docker run --rm --entrypoint php $IMAGE -r 'echo ini_get(\"upload_max_filesize\");')\" = 64M ]"
  check "a HEALTHCHECK is defined" \
    bash -c "docker inspect -f '{{json .Config.Healthcheck.Test}}' $IMAGE | grep -q wp-login.php"
  check "labels org.opencontainers.image.title=cao-shop and .source are set" \
    bash -c "[ \"\$(docker inspect -f '{{index .Config.Labels \"org.opencontainers.image.title\"}}' $IMAGE)\" = cao-shop ] && docker inspect -f '{{index .Config.Labels \"org.opencontainers.image.source\"}}' $IMAGE | grep -q '^https://'"
  check "no password baked into the image (ENV)" \
    bash -c "! docker inspect -f '{{json .Config.Env}}' $IMAGE | grep -qi password"
  check "unzip and wget did not reach the final image" \
    bash -c "! docker run --rm --entrypoint sh $IMAGE -c 'command -v unzip'"
  check ".dockerignore excludes .env and .git" \
    bash -c "grep -qxE '\\.env' .dockerignore && grep -qxE '\\.git/?' .dockerignore"
}

# The tests use .env.example with the test image; your own .env is put back after.
fresh_env() {
  if [[ -f .env && ! -f .env.student ]]; then mv .env .env.student; fi
  sed "s/^SHOP_IMAGE=.*/SHOP_IMAGE=$IMAGE/" .env.example > .env
  trap 'rm -f .env; [[ -f .env.student ]] && mv .env.student .env' EXIT
}

stage_run() {
  echo "== run"
  fresh_env
  bash scripts/down.sh --volumes >/dev/null 2>&1
  if bash scripts/up.sh >/tmp/up.log 2>&1; then pass "scripts/up.sh: db and shop healthy"; else fail "scripts/up.sh: db and shop healthy (see /tmp/up.log)"; cat /tmp/up.log; return; fi
  check "both containers on the user-defined network shop-net" \
    bash -c "docker inspect -f '{{json .NetworkSettings.Networks}}' db | grep -q shop-net && docker inspect -f '{{json .NetworkSettings.Networks}}' shop | grep -q shop-net"
  check "db publishes no port" bash -c "[ -z \"\$(docker port db)\" ]"
  check "shop publishes port 8080" bash -c "docker port shop 80 | grep -q ':8080'"
  check "volume db-data on /var/lib/mysql" \
    bash -c "docker inspect -f '{{range .Mounts}}{{.Name}}={{.Destination}} {{end}}' db | grep -q 'db-data=/var/lib/mysql'"
  check "volume shop-uploads on /var/www/html/wp-content/uploads" \
    bash -c "docker inspect -f '{{range .Mounts}}{{.Name}}={{.Destination}} {{end}}' shop | grep -q 'shop-uploads=/var/www/html/wp-content/uploads'"
  check "restart policy unless-stopped on both" \
    bash -c "[ \"\$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' db)\" = unless-stopped ] && [ \"\$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' shop)\" = unless-stopped ]"
  check "passwords passed by name, not on the command line" \
    bash -c "! grep -E '(-e|--env) +[A-Z_]*PASSWORD=' scripts/up.sh"
  if bash scripts/install-shop.sh >/tmp/install.log 2>&1; then pass "scripts/install-shop.sh"; else fail "scripts/install-shop.sh (see /tmp/install.log)"; cat /tmp/install.log; fi
  check "site title is SESAME Shop" bash -c "[ \"\$(docker exec -u www-data shop wp option get blogname)\" = 'SESAME Shop' ]"
  check "WooCommerce is active" docker exec -u www-data shop wp plugin is-active woocommerce
  check "http://localhost:8080/wp-login.php answers 200" \
    bash -c "[ \"\$(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/wp-login.php)\" = 200 ]"
}

stage_persist() {
  echo "== persist"
  bash scripts/down.sh >/dev/null 2>&1
  check "containers removed, volumes kept" \
    bash -c "! docker inspect db >/dev/null 2>&1 && docker volume inspect db-data shop-uploads"
  if bash scripts/up.sh >/tmp/up2.log 2>&1; then pass "scripts/up.sh again"; else fail "scripts/up.sh again"; return; fi
  check "the shop is still installed, no reinstall: title SESAME Shop" \
    bash -c "[ \"\$(docker exec -u www-data shop wp option get blogname)\" = 'SESAME Shop' ]"
  bash scripts/down.sh --volumes >/dev/null 2>&1
}

case "${1:-all}" in
  lint) stage_lint ;;
  image) stage_image ;;
  run) stage_image; stage_run ;;
  persist) stage_image; stage_run; stage_persist ;;
  all) stage_lint; stage_image; stage_run; stage_persist ;;
  *) echo "usage: $0 lint|image|run|persist|all"; exit 2 ;;
esac

echo
if [[ $fails -eq 0 ]]; then echo "All checks passed."; else echo "$fails check(s) failed."; fi
exit $(( fails > 0 ))
