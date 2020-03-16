#!/usr/bin/env bash

## Version we recommend.
DPDK_VERSION=${1:-18.11.6}
DPDK_PATH=${2:-http://fast.dpdk.org/rel}
DPDK_TARGET=/usr/local/src/dpdk-stable-${DPDK_VERSION}

## Download DPDK version.
wget ${DPDK_PATH}/dpdk-${DPDK_VERSION}.tar.gz -O - | tar xz -C /tmp

## mv it to $DPDK_TARGET as the canonical path
sudo cp -r /tmp/dpdk-stable-${DPDK_VERSION} ${DPDK_TARGET}

## Build DPDK and install into system paths.
## More info: https://doc.dpdk.org/guides/prog_guide/build-sdk-meson.html.
cd ${DPDK_TARGET} && sudo meson build
cd build && sudo ninja && sudo ninja install

## Create the necessary links and caches.
sudo ldconfig

## Cleanup
sudo rm -rf ${DPDK_TARGET}/build /tmp/*
