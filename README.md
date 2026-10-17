# Cloud Automation and Orchestration - Lab 5

SESAME University, Computer Engineering, ING5. Week 8: Docker.

The e-commerce shop of Workshop 1, WordPress with WooCommerce, now in containers. You write the image, run it next to a MariaDB container on a private network with volumes for the data, check that the data survives the containers, and push the image to a registry.

## Start

1. Open this repository in a Codespace, wait for `Toolbox ready`, run `make check` (Docker must be listed).
2. `cp .env.example .env` and change the passwords. `.env` is ignored by Git.
3. Follow the Lab 5 handout.

No Azure today: everything runs in your Codespace.

## Files

| Path | What |
| --- | --- |
| `Dockerfile` | the shop image, two stages (yours) |
| `.dockerignore` | what never enters the build (yours) |
| `config/uploads.ini` | given: PHP upload settings |
| `.env.example` | given: copy to `.env`, the passwords live there |
| `scripts/up.sh` | network, volumes and the two `docker run` commands (yours) |
| `scripts/down.sh`, `scripts/install-shop.sh` | given |
| `tests/run.sh` | the autograder's checks, run them with `make test` |
| `SUBMISSION.md` | answers |

## Grading (10 points, autograded on every push)

| Check | Points |
| --- | --- |
| Dockerfile from the official image with a `plugins` stage, hadolint clean | 1 |
| Image: WooCommerce, WP-CLI, PHP settings, health check, labels, no secret, small final stage, `.dockerignore` | 3 |
| Containers: network, volumes, ports, restart policy, both healthy, shop installed | 3 |
| Data survives removing the containers | 1 |
| `SUBMISSION.md` complete | 2 |

**Before you leave:** `make clean`, then stop your Codespace.
