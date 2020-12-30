# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define "server" do |machine|
    machine.vm.box = "generic/ubuntu1804"
    machine.vm.provider "libvirt" do |libvirt|
      libvirt.cpus = 1
      libvirt.memory = 1024
    end
    machine.vm.provision "shell", path: "./server.sh"
  end

end
