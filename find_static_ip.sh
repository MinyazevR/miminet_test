for ip in 192.168.56.{254..1} ; do
    grep -oE "$ip" dhcpd.conf > /dev/null 2>&1
    if [ $? != 0 ] ; then
      sed -i -e 's/vbox.vm.network "private_network", ip: "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}"/vbox.vm.network "private_network", ip: "'$ip'"/g' Vagrantfile
      # sudo ufw allow from $ip to any port nfs
      break
    fi
done
