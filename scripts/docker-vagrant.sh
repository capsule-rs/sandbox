#!/usr/bin/env bash

DPDK_DRIVER=${1:-uio_pci_generic}
VAGRANT_HOME_DIR=${2:-/home/vagrant}

sudo apt-get update \
    && sudo apt-get install -y \
      linux-headers-$(uname -r) \
    && sudo rm -rf /var/lib/apt/lists /var/cache/apt/archives

# `modprobe` DPDK driver.
modprobe $DPDK_DRIVER

# Set vm hugepages for sysctl.
grep -qxF "vm.nr_hugepages = 2048" /etc/sysctl.conf || \
    echo "vm.nr_hugepages = 2048" >> /etc/sysctl.conf
sysctl -e -p

# Start at "/vagrant/capsule" upon ssh.
grep -qxF "cd /vagrant" ${VAGRANT_HOME_DIR}/.bashrc || \
    echo "cd /vagrant" >> ${VAGRANT_HOME_DIR}/.bashrc
