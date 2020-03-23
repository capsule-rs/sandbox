NAMESPACE = capsule

BASE_DIR = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
DPDK_IMG = dpdk
DPDK_DEVBIND_IMG = dpdk-devbind
DPDK_MOD_IMG = dpdk-mod
DPDK_MOD_KERNEL = $(shell uname -r)
DPDK_VERSION = 18.11.6
DPDK_TARGET=/usr/local/src/dpdk-$(DPDK_VERSION)
RUST_VERSION = 1.42
RUST_BASE_IMG=rust:$(RUST_VERSION)-slim-buster
RR_VERSION=5.3.0

SANDBOX_IMG = sandbox
SANDBOX = $(NAMESPACE)/$(SANDBOX_IMG):$(DPDK_VERSION)-$(RUST_VERSION)
SANDBOX_LATEST = $(NAMESPACE)/$(SANDBOX_IMG):latest


.PHONY: build-all pull-all push-all \
        build-dpdk build-devbind build-mod build-sandbox \
        pull-dpdk pull-devbind pull-mod pull-sandbox \
        push-dpdk push-dpdk-latest push-devbind push-debind-latest push-mod \
        push-sandbox push-sandbox-latest \
        connect run

build-dpdk:
	@docker build --target $(DPDK_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION) $(BASE_DIR)

build-devbind:
	@docker build --target $(DPDK_DEVBIND_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION) $(BASE_DIR)

build-mod:
	@docker build --target $(DPDK_MOD_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
		-t $(NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL) $(BASE_DIR)

build-sandbox:
	@docker build --target $(SANDBOX_IMG) \
		--build-arg DPDK_VERSION=$(DPDK_VERSION) \
        --build-arg RUST_BASE_IMG=$(RUST_BASE_IMG) \
        --build-arg RR_VERSION=$(RR_VERSION) \
		-t $(SANDBOX) $(BASE_DIR)

build-all: build-dpdk build-devbind build-mod build-sandbox

connect:
	@docker exec -it $(SANDBOX_IMG) /bin/bash

pull-all: pull pull-devbind pull-mod pull-sandbox

pull-dpdk:
	@docker pull $(NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION)

pull-devbind:
	@docker pull $(NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION)

pull-mod:
	@docker pull $(NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL)

pull-sandbox:
	@docker pull $(SANDBOX)

push-all: push-dpdk push-dpdk-latest push-devbind push-devbind-latest push-mod \
          push-sandbox push-sandbox-latest

push-dpdk:
	@echo $(NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION)
	@docker push $(NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION)

push-dpdk-latest:
	@docker tag $(NAMESPACE)/$(DPDK_IMG):$(DPDK_VERSION) $(NAMESPACE)/$(DPDK_IMG):latest
	@docker push $(NAMESPACE)/$(DPDK_IMG):latest

push-devbind:
	@docker push $(NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION)

push-devbind-latest:
	@docker tag $(NAMESPACE)/$(DPDK_DEVBIND_IMG):$(DPDK_VERSION) $(NAMESPACE)/$(DPDK_DEVBIND_IMG):latest
	@docker push $(NAMESPACE)/$(DPDK_DEVBIND_IMG):latest

push-mod:
	@docker push $(NAMESPACE)/$(DPDK_MOD_IMG):$(DPDK_VERSION)-$(DPDK_MOD_KERNEL)

push-sandbox:
	@docker push $(SANDBOX)

push-sandbox-latest:
	@docker tag $(SANDBOX) $(SANDBOX_LATEST)
	@docker push $(SANDBOX_LATEST)

run:
	@if [ "$$(docker images -q $(SANDBOX))" = "" ]; then \
		docker pull $(SANDBOX); \
	fi
	@docker run -it --rm --privileged --network=host --name $(SANDBOX_IMG) \
    --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -w /home/$(NAMESPACE) \
	-v /lib/modules:/lib/modules \
	-v /dev/hugepages:/dev/hugepages \
	-v $(BASE_DIR)/nb2:/home/$(NAMESPACE) \
	$(SANDBOX) /bin/bash
