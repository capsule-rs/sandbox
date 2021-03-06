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

DPDK_DRIVER=${1:-uio_pci_generic}
DPDK_DEVICES=${2:-0000:00:08.0}
VAGRANT_HOME_DIR=${3:-/home/vagrant}

# `modprobe` DPDK driver.
modprobe "$DPDK_DRIVER"

# Set vm hugepages for sysctl.
grep -qxF "vm.nr_hugepages = 2048" /etc/sysctl.conf || \
    echo "vm.nr_hugepages = 2048" >> /etc/sysctl.conf
sysctl -e -p

# Source `cargo` for root user.
grep -qxF "source $HOME/.cargo/env" "$HOME/.bashrc" || \
    echo "source $HOME/.cargo/env" >> "$HOME/.bashrc"

# Start at "/vagrant/capsule" upon ssh.
grep -qxF "cd /vagrant/capsule" "${VAGRANT_HOME_DIR}/.bashrc" || \
    echo "cd /vagrant/capsule" >> "${VAGRANT_HOME_DIR}/.bashrc"

# Turn CARGO_INCREMENTAL off for vagrant/sudo users.
grep -qxF "export CARGO_INCREMENTAL=0" "$HOME/.bashrc" || \
    echo "export CARGO_INCREMENTAL=0" >> "$HOME/.bashrc"
grep -qxF "export CARGO_INCREMENTAL=0" "${VAGRANT_HOME_DIR}/.bashrc" || \
    echo "export CARGO_INCREMENTAL=0" >> "${VAGRANT_HOME_DIR}/.bashrc"
echo "export PATH='/usr/sbin:/:$PATH'" >> "${VAGRANT_HOME_DIR}/.bashrc"


# Helpful cargo installs for environment, including,
#   - cargo-watch (https://crates.io/crates/cargo-watch),
#   - cargo-expand (https://crates.io/crates/cargo-expand).
cargo install cargo-watch && cp "$HOME/.cargo/bin/cargo-watch" "${VAGRANT_HOME_DIR}/.cargo/bin"
cargo install cargo-expand && cp "$HOME/.cargo/bin/cargo-expand" "${VAGRANT_HOME_DIR}/.cargo/bin"


# devbind to default device
dpdk-devbind.py --force -b "${DPDK_DRIVER}" "${DPDK_DEVICES}"

# insmod kni
if ! lsmod | grep rte_kni &> /dev/null ; then
    insmod /lib/modules/`uname -r`/extra/dpdk/rte_kni.ko
fi
