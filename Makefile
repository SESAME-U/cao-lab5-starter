.PHONY: help check build lint history up install down down-all ps logs registry push pull-test test clean

IMAGE ?= cao-shop:1.0
REGISTRY ?= localhost:5000

help:
	@echo "make check       verify the toolbox"
	@echo "make build       build the shop image ($(IMAGE))"
	@echo "make lint        hadolint on the Dockerfile"
	@echo "make history     the layers of the image and their size"
	@echo "make up          start db and shop (scripts/up.sh)"
	@echo "make install     install WordPress and activate WooCommerce (once)"
	@echo "make ps          the running containers"
	@echo "make logs        follow the shop logs (Ctrl+C to stop)"
	@echo "make down        remove the containers, keep the volumes"
	@echo "make down-all    remove the containers AND the volumes (data lost)"
	@echo "make registry    start a local registry on localhost:5000"
	@echo "make push        tag and push the image to the local registry"
	@echo "make test        run the autograder checks (builds cao-shop:test)"
	@echo "make clean       down-all, remove the registry and the images"

check:
	@bash scripts/check.sh

build:
	docker build -t $(IMAGE) .

lint:
	docker run --rm -i hadolint/hadolint:v2.14.0 hadolint - < Dockerfile

history:
	docker history $(IMAGE)

up:
	@bash scripts/up.sh

install:
	@bash scripts/install-shop.sh

ps:
	docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

logs:
	docker logs -f shop

down:
	@bash scripts/down.sh

down-all:
	@bash scripts/down.sh --volumes

registry:
	docker run -d --name registry --restart unless-stopped -p 5000:5000 -v registry-data:/var/lib/registry registry:3.1.2

push:
	docker tag $(IMAGE) $(REGISTRY)/$(IMAGE)
	docker push $(REGISTRY)/$(IMAGE)

pull-test:
	docker rmi $(REGISTRY)/$(IMAGE)
	docker pull $(REGISTRY)/$(IMAGE)

test:
	@bash tests/run.sh all

clean: down-all
	-docker rm -f registry
	-docker volume rm registry-data
	-docker rmi $(IMAGE) cao-shop:test $(REGISTRY)/$(IMAGE)
