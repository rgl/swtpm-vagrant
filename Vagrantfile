Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 1024
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provision :shell, path: 'provision-base.sh'
  config.vm.provision :shell, path: 'build-swtpm.sh'
  config.vm.provision :shell, path: 'provision-swtpm.sh'
end
