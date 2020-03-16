#!/usr/bin/env bash

## Minimal installs.
sudo apt-get update \
  && sudo apt-get install -y \
    build-essential \
    ca-certificates \
    clang \
    curl \
    git \
    kmod \
    libclang-dev \
    libnuma-dev \
    libpcap-dev \
    libssl-dev \
    linux-headers-$(uname -r) \
    llvm-dev \
    pkg-config \
    python3-setuptools \
    python3-pip \
    wget \
  && sudo pip3 install --system wheel \
    meson \
    ninja \
  && sudo rm -rf /var/lib/apt/lists /var/cache/apt/archives
