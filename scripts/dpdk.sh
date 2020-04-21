#!/usr/bin/env bash
#
# Copyright 2019 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

## Version we recommend.
DPDK_VERSION=${1:-18.11.7}
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
