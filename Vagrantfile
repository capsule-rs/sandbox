# -*- mode: ruby -*-

VAGRANTFILE_API_VERSION = "2"

# Required Vagrant plugins.
['vagrant-reload', 'vagrant-disksize', 'vagrant-vbguest'].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "Vagrant plugin #{plugin} is not installed!"
  end
end

# Default Vagrant vars.
$devbind_img = "capsule/dpdk-devbind:18.11.6"
$dpdkmod_img = "capsule/dpdk-mod:18.11.6-`uname -r`"
$sandbox_img = "capsule/sandbox:18.11.6-1.42"

$dpdk_driver = "uio_pci_generic"
$dpdk_devices = "0000:00:08.0"
$vhome = "/home/vagrant"

# All Vagrant configuration is done here. The most common configuration
# options are documented and commented below. For a complete reference,
# please see the online documentation at https://docs.vagrantup.com.
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.allowed_synced_folder_types = [:virtualbox, :vmware, :sshfs]
  config.vm.box = "debian/buster64"
  config.vm.box_check_update = false
  config.vm.post_up_message = "hello capsule!"

  config.disksize.size = "45GB"
  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  # Specific IP. This is needed because DPDK takes over the NIC.
  config.vm.network "private_network", ip: "10.100.1.10"

  # Forward user-defined ports.
  ENV['FORWARDED_PORTS'].to_s.split(" ").each do |port|
    config.vm.network :forwarded_port, guest: port, host: port
  end

  # Pull and run our image(s) in order to do the devbind and insmod for kni.
  config.vm.define "docker", primary: true do |docker|
    # VirtualBox-specific default configuration
    docker.vm.provider "virtualbox" do |vb, override|
      # Set machine name, memory and CPU limits
      vb.name = "debian:buster-capsule-docker"
      vb.memory = 8192
      vb.cpus = 4
      vb.default_nic_type = "virtio"

      # Configure VirtualBox to enable passthrough of SSE 4.1 and SSE 4.2 instructions,
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]

      # Allow promiscuous mode for host-only adapter
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

      # Sync folder via VirtualBox type.
      override.vm.synced_folder ".", "/vagrant", create: true, type: "virtualbox"
    end

    docker.vm.provision "shell", path: "scripts/docker-vagrant.sh", :args => [$dpdk_driver, $vhome]
    docker.vm.provision "docker" do |d|
    ## TODO: Uncomment runs for manual builds or whole block once contains on hub.docker.com
    #   d.pull_images "#{$devbind_img}"
    #   d.pull_images "#{$dpdkmod_img}"
    #   d.pull_images "#{$sandbox_img}"
    #   d.run "#{$devbind_img}",
    #         auto_assign_name: false,
    #         args: %W(--rm
    #                  --privileged
    #                  --network=host).join(" "),
    #         restart: "no",
    #         daemonize: true,
    #         cmd: "/bin/bash -c 'dpdk-devbind.py --force -b #{$dpdk_driver} #{$dpdk_devices}'"
    #   d.run "#{$dpdkmod_img}",
    #         auto_assign_name: false,
    #         args: %W(--rm
    #                  --privileged
    #                  --network=host).join(" "),
    #         restart: "no",
    #         daemonize: true,
    #         cmd: "insmod /lib/modules/`uname -r`/extra/dpdk/rte_kni.ko"
    end
  end

  config.vm.define "vm", primary: false, autostart: false do |v|
    # VirtualBox-specific default configuration
    v.vm.provider "virtualbox" do |vb, override|
      # Set machine name, memory and CPU limits
      vb.name = "debian:buster-capsule-vm"
      vb.memory = 8192
      vb.cpus = 4
      vb.default_nic_type = "virtio"

      # Configure VirtualBox to enable passthrough of SSE 4.1 and SSE 4.2 instructions,
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
      vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]

      # Allow promiscuous mode for host-only adapter
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

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
