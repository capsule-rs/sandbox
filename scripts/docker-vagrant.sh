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
VAGRANT_HOME_DIR=${2:-/home/vagrant}

# `modprobe` DPDK driver.
modprobe $DPDK_DRIVER

# Set vm hugepages for sysctl.
grep -qxF "vm.nr_hugepages = 2048" /etc/sysctl.conf || \
    echo "vm.nr_hugepages = 2048" >> /etc/sysctl.conf
sysctl -e -p

# Start at "/vagrant/capsule" upon ssh.
grep -qxF "cd /vagrant" ${VAGRANT_HOME_DIR}/.bashrc || \
    echo "cd /vagrant" >> ${VAGRANT_HOME_DIR}/.bashrc
