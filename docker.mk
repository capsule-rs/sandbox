BASE_DIR = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
BUILDER_BASE_IMG = debian:buster-slim
DOCKER_NAMESPACE = getcapsule

DPDK_IMG = dpdk
DPDK_DEVBIND_IMG = dpdk-devbind
DPDK_MOD_IMG = dpdk-mod
DPDK_MOD_KERNEL = $(shell uname -r)
DPDK_TARGET = /usr/local/src/dpdk-$(DPDK_VERSION)
DPDK_VERSION = 19.11.6

RR_VERSION = 5.5.0
RUST_BASE_IMG = rust:$(RUST_VERSION)-slim-buster
RUST_VERSION = 1.62

SANDBOX_IMG = sandbox
SANDBOX = $(DOCKER_NAMESPACE)/$(SANDBOX_IMG):$(DPDK_VERSION)-$(RUST_VERSION)
SANDBOX_LATEST = $(DOCKER_NAMESPACE)/$(SANDBOX_IMG):latest

.PHONY: build-all pull-all push-all \
        build-dpdk build-devbind build-mod build-sandbox \
        pull-dpdk pull-devbind pull-mod pull-sandbox \
        push-dpdk push-dpdk-latest push-devbind push-debind-latest push-mod \
        push-sandbox push-sandbox-latest \
        connect-sandbox run-sandbox test-sandbox

build-dpdk:
	@docker build --target $(DPDK_IMG) \
		--build-arg BUILDER_BASE_IMG=$(BUILDER_BASE_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(DOCKER_NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION) $(BASE_DIR)

build-devbind:
	@docker build --target $(DPDK_DEVBIND_IMG) \
		--build-arg BUILDER_BASE_IMG=$(BUILDER_BASE_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION) $(BASE_DIR)

build-mod:
	@docker build --target $(DPDK_MOD_IMG) \
		--build-arg BUILDER_BASE_IMG=$(BUILDER_BASE_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(DOCKER_NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL) $(BASE_DIR)

build-sandbox:
	@docker build --target $(SANDBOX_IMG) \
		--build-arg BUILDER_BASE_IMG=$(BUILDER_BASE_IMG) \
		--build-arg DEBUG=true \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		--build-arg RR_VERSION=$(RR_VERSION) \
		--build-arg RUST_BASE_IMG=$(RUST_BASE_IMG) \
		-t $(SANDBOX) $(BASE_DIR)

build-all: build-dpdk build-devbind build-mod build-sandbox

connect-sandbox:
	@docker exec -it $(SANDBOX_IMG) /bin/bash

pull-all: pull-dpdk pull-devbind pull-mod pull-sandbox

pull-dpdk:
	@docker pull $(DOCKER_NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION)

pull-devbind:
	@docker pull $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION)

pull-mod:
	@docker pull $(DOCKER_NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL)

pull-sandbox:
	@docker pull $(SANDBOX)

push-all: push-dpdk push-dpdk-latest push-devbind push-devbind-latest push-mod \
          push-sandbox push-sandbox-latest

push-dpdk:
	@docker push $(DOCKER_NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION)

push-dpdk-latest:
	@docker tag $(DOCKER_NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION) $(DOCKER_NAMESPACE)/$(DPDK_IMG):latest
	@docker push $(DOCKER_NAMESPACE)/$(DPDK_IMG):latest

push-devbind:
	@docker push $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION)

push-devbind-latest:
	@docker tag $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION) $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):latest
	@docker push $(DOCKER_NAMESPACE)/$(DPDK_DEVBIND_IMG):latest

push-mod:
	@docker push $(DOCKER_NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL)

push-sandbox:
	@docker push $(SANDBOX)

push-sandbox-latest:
	@docker tag $(SANDBOX) $(SANDBOX_LATEST)
	@docker push $(SANDBOX_LATEST)

run-sandbox:
	@if [ "$$(docker images -q $(SANDBOX))" = "" ]; then \
	docker pull $(SANDBOX); \
	fi
	@docker run -it --rm --privileged --network=host --name $(SANDBOX_IMG) \
	--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
	-w /home/capsule \
	-v /lib/modules:/lib/modules \
	-v /dev/hugepages:/dev/hugepages \
	-v $(BASE_DIR)/capsule:/home/capsule \
	$(SANDBOX) /bin/bash

test-sandbox:
	@if [ "$$(docker images -q $(SANDBOX))" = "" ]; then \
	docker pull $(SANDBOX); \
	fi
	@docker run --rm --privileged --network=host --name $(SANDBOX_IMG) \
	-w /home/capsule \
	-v /lib/modules:/lib/modules \
	-v /dev/hugepages:/dev/hugepages \
	-v $(BASE_DIR)/capsule:/home/capsule \
	$(SANDBOX) make test
