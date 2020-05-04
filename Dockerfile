ARG BUILDER_BASE_IMG
ARG RUST_BASE_IMG

FROM $BUILDER_BASE_IMG as builder

ARG DEBUG=false
ARG DPDK_VERSION
ARG DPDK_PATH=http://fast.dpdk.org/rel
ARG DPDK_TARGET=/usr/local/src/dpdk-stable-${DPDK_VERSION}
ARG DPDK_MACHINE=corei7
ARG DPDK_TUNE_TYPE=corei7-avx

RUN apt-get update \
  && apt-get install -y \
    build-essential \
    libnuma-dev \
    libpcap-dev \
    linux-headers-$(uname -r) \
    python3-setuptools \
    python3-pip \
    wget \
  && pip3 install \
    meson \
    ninja \
    wheel \
  && wget ${DPDK_PATH}/dpdk-${DPDK_VERSION}.tar.gz -O - | tar xz -C /usr/local/src

WORKDIR ${DPDK_TARGET}

RUN meson build \
  && cd build \
  && if [ "$DEBUG" = "true" ]; then meson configure -Dbuildtype=debug; fi \
  && meson configure -Dmachine=${DPDK_MACHINE} \
  && meson configure -Dc_args=-mtune=${DPDK_TUNE_TYPE} \
  && ninja \
  && ninja install \
  && rm -rf ${DPDK_TARGET}/build /usr/local/bin/dpdk-test \
    /usr/local/bin/dpdk-test-* /usr/local/bin/meson /usr/local/bin/ninja

##
## dpdk
##
FROM debian:buster-slim as dpdk

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /usr/local/lib/x86_64-linux-gnu /usr/local/lib/x86_64-linux-gnu

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libnuma1 \
    libpcap0.8 \
  && apt-get autoremove -y \
  && apt-get clean \
  && ldconfig \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

##
## dpdk-devbind utility
##
FROM debian:buster-slim as dpdk-devbind

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /usr/local/bin/dpdk-devbind.py /usr/local/bin/dpdk-devbind.py

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    iproute2 \
    pciutils \
    python \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

##
## dpdk-mod utility
##
FROM debian:buster-slim as dpdk-mod

LABEL maintainer="Capsule Developers <capsule-dev@googlegroups.com>"

COPY --from=builder /lib/modules /lib/modules

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    kmod \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

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
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    gdb \
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
    python-pyelftools \
    python3-setuptools \
    python3-pip \
    tcpdump \
    wget \
  && ldconfig \
  && pip3 install \
    meson \
    ninja \
    wheel \
  && rustup component add \
    clippy \
    rust-docs \
    rustfmt \
    rust-src \
  && cargo install cargo-watch \
  && cargo install cargo-expand \
  && wget -P /tmp https://github.com/mozilla/rr/releases/download/${RR_VERSION}/rr-${RR_VERSION}-Linux-$(uname -m).deb \
  && dpkg -i /tmp/rr-${RR_VERSION}-Linux-$(uname -m).deb \
  && apt-get purge -y \
    wget \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf .cargo/registry /var/lib/apt/lists/* /var/cache/apt/archives /tmp/*
