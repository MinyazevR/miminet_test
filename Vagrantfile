#-*- mode: ruby -*-
# vi: set ft=ruby :

#require 'getoptlong'
#require 'rbconfig'

#opts = GetoptLong.new(
 # [ '--vm', GetoptLong::REQUIRED_ARGUMENT]
#)

#opts.ordering=(GetoptLong::REQUIRE_ORDER)

#vm=''

#opts.each do |opt, arg|
 # case opt
  #  when '--vm'
   #   unless arg == 'virtualbox' || arg == 'vmware'
    #    abort("На данный момент поддерживается только --vm=virtualbox и --vm==vmware")
     # end
      #vm=arg
  #end
#end

def os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
    end
  )
end

Vagrant.configure("2") do |config|

  box_configs = lambda do |box|
    box.vm.box = "bento/ubuntu-22.04"
    box.vm.hostname = 'miminethost'
    # Переброска стандартного порта, на котором запускается Flask при локальном деплое
    box.vm.network "forwarded_port", guest: 5001, host: 5001

    # Shared folder - текущая, для гостевой ---/vagrant
    if os == :windows
      box.vm.synced_folder ".", "/vagrant",
        type: "smb"
    else
      # в стандартах RFC для NFSv4 не советуется использовать UDP    
      box.vm.synced_folder ".", "/vagrant",
        type: "nfs",
        nfs_version: 4,
        nfs_udp: false
    end

    # Используем ansible
    box.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "vagrant/playbook.yml"
    end
  end
    
  config.vm.define "vbox", autostart: false do |vbox|
    unless os == :windows
      # Приватная сеть для использования NFS в virtualbox
      # NFS используем так как vboxfs нормально не поддерживает shared folder    
      # (с dhcp автоматически найдется свободный ip для гостевой машины,
      # но вы можете задать его сами)
      vbox.vm.network "private_network", ip: "dhcp"
    end

    vbox.vm.provider "virtualbox" do |v, override|
  
      # Оперативная память, пока что подобрал от балды, но при 1024 точно был system is deadlocked on memory
      v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--name", "miminet"]
      
      # Для диагностики гостевой машины через COM1 с Raw File
      v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
      v.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
      v.gui = false
      box_configs.call override
    end
  end

  config.vm.define "vmware", autostart: false  do |vmware|
    vmware.vm.provider "vmware_desktop" do |v, override|
      v.vmx["displayName"] = "miminet"
      v.vmx["memsize"] = "1024"
      box_configs.call override
    end
  end
end