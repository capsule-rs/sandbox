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

# -*- mode: ruby -*-

VAGRANTFILE_API_VERSION = "2"

# Required Vagrant plugins.
['vagrant-reload', 'vagrant-disksize', 'vagrant-vbguest'].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "Vagrant plugin #{plugin} is not installed!"
  end
end

# Default Vagrant vars.
$devbind_img = "getcapsule/dpdk-devbind:19.11.6"
$dpdkmod_img = "getcapsule/dpdk-mod:19.11.6-`uname -r`"
$sandbox_img = "getcapsule/sandbox:19.11.6-1.50"

$dpdk_driver = "uio_pci_generic"
$dpdk_devices = "0000:00:08.0 0000:00:09.0"
$vhome = "/home/vagrant"

# All Vagrant configuration is done here. The most common configuration
# options are documented and commented below. For a complete reference,
# please see the online documentation at https://docs.vagrantup.com.
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.allowed_synced_folder_types = [:virtualbox, :vmware, :sshfs]
  config.vm.box = "debian/contrib-buster64"
  config.vm.box_check_update = false
  config.vm.post_up_message = "hello Capsule!"

  config.disksize.size = "45GB"
  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  # Specific IPs. These is needed because DPDK takes over the NIC.
  config.vm.network "private_network", ip: "10.100.1.10", :mac => "020000FFFF00"
  config.vm.network "private_network", ip: "10.100.1.11", :mac => "020000FFFF01"

  # NIC on the same subnet as the two bound to DPDK.
  config.vm.network "private_network", ip: "10.100.1.254", :mac => "020000FFFFFF"

  # Pull and run our image(s) in order to do the devbind and insmod for kni.
  config.vm.define "docker", primary: true do |docker|
    # VirtualBox-specific default configuration
    docker.vm.provider "virtualbox" do |vb, override|
      # Set machine name, memory and CPU limits
      vb.name = "debian-buster-capsule-docker"
      vb.memory = 8192
      vb.cpus = 4
      vb.default_nic_type = "virtio"

      # Configure VirtualBox to enable passthrough of SSE 4.1 and SSE 4.2 instructions,
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]

      # Sync folder via VirtualBox type.
      override.vm.synced_folder ".", "/vagrant", create: true, type: "virtualbox"
    end

    docker.vm.provision "shell", path: "scripts/docker-vagrant.sh", :args => [$dpdk_driver, $vhome]
    docker.vm.provision "docker" do |d|
      d.pull_images "#{$devbind_img}"
      d.pull_images "#{$dpdkmod_img}"
      d.pull_images "#{$sandbox_img}"
      d.run "#{$devbind_img}",
            auto_assign_name: false,
            args: %W(--rm
                     --privileged
                     --network=host
                     -v /lib/modules:/lib/modules).join(" "),
            restart: "no",
            daemonize: true,
            cmd: "/bin/bash -c 'dpdk-devbind.py --force -b #{$dpdk_driver} #{$dpdk_devices}'"
      d.run "#{$dpdkmod_img}",
            auto_assign_name: false,
            args: %W(--rm
                     --privileged
                     --network=host).join(" "),
            restart: "no",
            daemonize: true,
            cmd: "insmod /lib/modules/`uname -r`/extra/dpdk/rte_kni.ko carrier=on"
    end
  end

  config.vm.define "vm", primary: false, autostart: false do |v|
    # VirtualBox-specific default configuration
    v.vm.provider "virtualbox" do |vb, override|
      # Set machine name, memory and CPU limits
      vb.name = "debian-buster-capsule-vm"
      vb.memory = 8192
      vb.cpus = 4
      vb.default_nic_type = "virtio"

      # Configure VirtualBox to enable passthrough of SSE 4.1 and SSE 4.2 instructions,
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]

      # Sync folder via VirtualBox type.
      override.vm.synced_folder ".", "/vagrant", create: true, type: "virtualbox"
    end

    # Setup for ubuntu/debian.
    v.vm.provision "shell", path: "scripts/setup.sh"
    # Install DPDK.
    v.vm.provision "shell", path: "scripts/dpdk.sh"
    # Install for Vagrant user.
    v.vm.provision "shell", privileged: false, path: "scripts/rustup.sh"
    # Install for root user, as DPDK apps require sudo, e.g. `cargo run`.
    v.vm.provision "shell", path: "scripts/rustup.sh"
    # Setup specific to this vm.
    v.vm.provision "shell", path: "scripts/vm-vagrant.sh", :args => [$dpdk_driver, $dpdk_devices, $vhome]
  end
end
