ARG BUILDER_BASE_IMG
ARG RUST_BASE_IMG

FROM $BUILDER_BASE_IMG as builder

ARG DPDK_VERSION
ARG DPDK_PATH=http://fast.dpdk.org/rel
ARG DPDK_TARGET=/usr/local/src/dpdk-stable-${DPDK_VERSION}

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    libnuma-dev \
    libpcap-dev \
    linux-headers-$(uname -r) \
    python3-setuptools \
    python3-pip \
    wget \
    ninja-build \
  && pip3 install \
    meson \
    ninja \
    wheel \
  && wget ${DPDK_PATH}/dpdk-${DPDK_VERSION}.tar.gz -O - | tar xz -C /usr/local/src

WORKDIR ${DPDK_TARGET}

RUN meson build \
  && cd build \
  && ninja \
  && ninja install \
  && rm -rf ${DPDK_TARGET}/build

##
## dpdk
##
FROM debian:buster-slim as dpdk

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    libnuma1 \
    libpcap0.8 \
  && ldconfig \
  && rm -rf /var/lib/apt/lists /var/cache/apt/archives

##
## dpdk-devbind utility
##
FROM debian:buster-slim as dpdk-devbind

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /usr/local/bin/dpdk-devbind.py /usr/local/bin/dpdk-devbind.py

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    iproute2 \
    pciutils \
    python \
  && rm -rf /var/lib/apt/lists /var/cache/apt/archives

##
## dpdk-mod utility
##
FROM debian:buster-slim as dpdk-mod

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /lib/modules /lib/modules

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    kmod \
  && rm -rf /var/lib/apt/lists /var/cache/apt/archives

##
## capsule-sandbox for development
##
FROM $RUST_BASE_IMG as sandbox

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

ARG DPDK_VERSION
ARG DPDK_TARGET=/usr/local/src/dpdk-stable-${DPDK_VERSION}
ARG RR_VERSION

ENV CARGO_INCREMENTAL=0
ENV RUST_BACKTRACE=1

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu
COPY --from=builder /usr/local/include /usr/local/include
COPY --from=builder ${DPDK_TARGET} ${DPDK_TARGET}

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
    build-essential \
    ca-certificates \
    clang \
    curl \
    gdb \
    git \
    gnuplot \
    iproute2 \
    kmod \
    libclang-dev \
    libnuma-dev \
    libpcap-dev \
    libssl-dev \
    llvm-dev \
    pciutils \
    pkg-config \
    python \
    python-pip \
    python-setuptools \
    tcpdump \
    wget \
  && ldconfig \
  && rustup component add \
    clippy \
    rust-docs \
    rustfmt \
    rust-src \
  && cargo install cargo-watch \
  && cargo install cargo-expand \
  && wget -P /tmp https://github.com/mozilla/rr/releases/download/${RR_VERSION}/rr-${RR_VERSION}-Linux-$(uname -m).deb \
  && dpkg -i /tmp/rr-${RR_VERSION}-Linux-$(uname -m).deb \
  && rm -rf .cargo/registry /var/lib/apt/lists /var/cache/apt/archives /tmp/*
