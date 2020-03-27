[![Apache-2.0 licensed][apache-badge]][apache-url]
[![CI-Github Actions][gh-actions-badge]][gh-actions-url]
[![Code of Conduct][code-of-conduct-badge]][code-of-conduct-url]
[![Discord channel][discord-badge]][discord-url]

[apache-badge]: https://img.shields.io/github/license/capsule-rs/sandbox
[apache-url]: LICENSE
[gh-actions-badge]: https://github.com/capsule-rs/sandbox/workflows/build/badge.svg
[gh-actions-url]: https://github.com/capsule-rs/sandbox/actions
[code-of-conduct-badge]: https://img.shields.io/badge/%E2%9D%A4-code%20of%20conduct-ff69b4
[code-of-conduct-url]: CODE_OF_CONDUCT.md
[discord-badge]: https://img.shields.io/discord/690406128567320597.svg?logo=discord
[discord-url]: https://discord.gg/qZ9G99y

# Capsule sandbox

The Capsule sandbox is a containerized development environment for building [Capsule](https://github.com/capsule-rs/capsule) applications in Rust.

## Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [Vagrant and VirtualBox](#vagrant-and-virtualbox)
  * [Linux Distributions](#linux-distributions)
  * [Without Docker](#without-docker)
  * [Kernel NIC Interface](#kernel-nic-interface)
* [Packaging for Release](#packaging-for-release)
* [Contributing](#contributing)
* [Code of Conduct](#code-of-conduct)
* [License](#license)

## Introduction

`Capsule` is built on Intel's [Data Plane Development Kit](https://www.dpdk.org/) release 18.11. While it is written in Rust, it needs to be able to call `DPDK`'s C functions installed separately on the host as shared dynamic libaries. To make developing and running Capsule applications easy, we created the sandbox container with all the necessary dependencies. You can pull down the container and start writing network functions in stable `Rust` right away.

## Getting Started

To run the [sandbox](https://hub.docker.com/repository/docker/getcapsule/sandbox), the docker host must run on a Linux distribution. `DPDK` requires either Linux or FreeBSD. We plan to add FreeBSD support in the future.

### Vagrant and VirtualBox

The quickest way to start the sandbox is to use the Vagrant virtual machine included in this repository. If you are developing on either MacOS or Windows, this is the only way to write a `Capsule` application.

After cloning this repository, you can start the vagrant VM using commands,

```
host$ vagrant up
host$ vagrant ssh
```

Now you are inside a `Debian` VM. The system is already preconfigured for DPDK. To run the sandbox, use the command,

```
vagrant$ docker run -it --rm \
    --privileged \
    --network=host \
    --name sandbox \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v /lib/modules:/lib/modules \
    -v /dev/hugepages:/dev/hugepages \
    getcapsule/sandbox:18.11.6-1.42 /bin/bash
```

The sandbox must run in privileged mode with host networking, so it can access the two network interfaces on the Vagrant host dedicated to DPDK applications.

```
vagrant$ lspci
00:08.0 Ethernet controller: Red Hat, Inc Virtio network device
00:09.0 Ethernet controller: Red Hat, Inc Virtio network device
```

To use `Capsule`, add it as a dependency in your `Cargo.toml`,

```
[dependencies]
capsule = "0.1"
```

You should also mount the working directory of your project as a volume for the sandbox. Then you can use `cargo` commands inside the container as normal.

### Linux Distributions

Alternatively, if you are already running a Linux operating system and do not wish to use `Vagrant`, you should be able to run the sandbox container directly. We've tested the sandbox on `Debian Buster`, `Ubuntu Bionic` and `CentOS 7`. Other Linux distributions and versions may work similarly with minor tweaks, if you are not running the versions we tested on.

You need to make a few configuration changes to support `DPDK`.

`DPDK` needs a small kernel module to set up the device, map device memory to user-space and register interrupts. The standard `uio_pci_generic` module included in the Linux kernel can provide the capability. To load the module, use the command,

```
host$ sudo modprobe uio_pci_generic
```

Debian and CentOS by default include this module. If you are on an Ubuntu host, `uio_pci_generic` is not part of the base system. You will need to install an additional package,

```
sudo apt install linux-modules-extra-$(uname -r)
```

DPDK also needs `HugePages` support for the large memory pool allocation used for packet buffers. To enable `HugePages`, use the following commands,

```
host$ sudo su
host$ echo "vm.nr_hugepages = 2048" >> /etc/sysctl.conf
host$ sysctl -e -p
host$ exit
```

Before your `Capsule` application can access a network interface on the host, the interface must be bound to a DPDK compatible driver with the [`dpdk-devbind`](https://doc.dpdk.org/guides/tools/devbind.html) utility. To bind the driver, find the interface's PCI address and use the command,

```
host$ docker pull getcapsule/dpdk-devbind:18.11.6
host$ docker run --rm --privileged --network=host \
    -v /lib/modules:/lib/modules \
    getcapsule/dpdk-devbind:18.11.6 \
    /bin/bash -c 'dpdk-devbind.py --force -b uio_pci_generic #PCI_ADDR#'
```

Once you've made the necessary changes, you can pull down the sandbox container and run it,

```
host$ docker pull getcapsule/sandbox:18.11.6-1.42
host$ docker run ...
```

### Without Docker

If you choose not to use `Docker`, or if you are using a Linux distribution incompatible with the `Debian` based sandbox, then you need to [install DPDK from source](https://doc.dpdk.org/guides/linux_gsg/build_dpdk.html) yourself.

In additional to the [required tools and libraries](https://doc.dpdk.org/guides/linux_gsg/sys_reqs.html#compilation-of-the-dpdk), you also need the library for packet captures to run some `Capsule` example applications. Install `libpcap-dev` for `Debian`/`Ubuntu` or `libpcap-devel` for `RHEL`/`CentOS`/`Fedora`.

Once you have installed all the necessary tools and libraries on your system, you should use our [script](scripts/dpdk.sh) to install the version of DPDK that `Capsule` uses.

You can also use another [script](scripts/rustup.sh) to install the latest stable `Rust` if you don't have that setup already. Since kernel 4.0, running `DPDK` applications requires `root` privileges. You must install the `Rust` toolchain for the `root` user as well if you want to run your project with `cargo run`.

We've provided another Vagrant virtual machine for development sans `Docker` if you don't want to manually install `DPDK`.

```
host$ vagrant up vm
host$ vagrant ssh
```

### Kernel NIC Interface

If your application uses [KNI](https://doc.dpdk.org/guides/prog_guide/kernel_nic_interface.html), you will need the kernel module `rte_kni`. Kernel modules are version specific. We may provide precompiled modules for different kernel versions and Linux distributions in the future. But for now, you will have to compile it yourself by installing the kernel headers or sources required to build kernel modules on your system, and then build `DPDK` from source. Follow the directions above.

Once compiled, you can load it using command,

```
host$ sudo insmod /lib/modules/`uname -r`/extra/dpdk/rte_kni.ko
```

## Packaging for Release

When packaging your application for release, the package must include the shared `DPDK` libraries and have as dependencies `libnuma` and `libpcap` for your Linux distribution.

If you want to containerize your release, you can use [`getcapsule/dpdk:18.11.6`](https://hub.docker.com/repository/docker/getcapsule/dpdk) as the base image which includes `libnuma`, `libpcap` and `DPDK`. For other packaging methods, you can find the `DPDK` libraries in `/usr/local/lib/x86_64-linux-gnu`.

## Contributing

Thanks for your help improving the project! We have a [contributing guide](https://github.com/capsule-rs/capsule/blob/master/CONTRIBUTING.md) to help you get involved in the `Capsule` project.

## Code of Conduct

This project and everyone participating in it are governed by the [Capsule Code Of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to this Code. Please report any violations to the code of conduct to capsule-dev@googlegroups.com.

## License

This project is licensed under the [Apache-2.0 license](LICENSE).
