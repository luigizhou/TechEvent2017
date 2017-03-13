# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "4096"
     vb.cpus = 4
     vb.linked_clone = true
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Create Ansible Management node
  config.vm.define "demo" do |demo|
        demo.vm.hostname = "demo.terraform.lcl"
        demo.vm.provision "shell", inline: "sudo -l mkdir -p /tmp/demo-box"
        demo.vm.provision :file, source: Dir.getwd + "/techevent", destination: "/tmp/techevent"
        demo.vm.provision "shell", inline: "sudo mv /tmp/techevent /home/vagrant/ && sudo chown -R vagrant:vagrant /home/vagrant/techevent"
        demo.vm.provision :file, source: Dir.getwd + "/config.sh", destination: "/tmp/demo-box/config.sh"
        demo.vm.provision :file, source: Dir.getwd + "/ansible.cfg", destination: "/tmp/demo-box/ansible.cfg"
        demo.vm.provision :file, source: Dir.getwd + "/box.yml", destination: "/tmp/demo-box/box.yml"
        demo.vm.provision :file, source: Dir.getwd + "/terraform.sh.j2", destination: "/tmp/demo-box/terraform.sh.j2"
        demo.vm.provision "shell" do |s|
          s.inline = "mkdir -pv /opt/demo/ansible && cd /tmp/demo-box && chmod +x ./config.sh && ./config.sh"
          s.privileged = true
        end
  end
end