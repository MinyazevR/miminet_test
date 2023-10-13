# Кроссплатформенность miminet.
На данный момент в miminet используются некроссфплаторменные библиотеки, в частности mininet и ipmininet, которые поддерживаются только на Ubuntu, Fedora, Debian.
Промежуточной задачей является сделать возможной разработку для Windows и MacOS

## Требования:
1. Быстрота развертывания (можно развернуть весь miminet несколькими командами)
2. Переносимость.
3. В некотором смысле изолированность системы.

## Vagrant + Virtualbox(hyperv, vmware)
Vagrant --- менеджер виртуальных машин для создания и управлениями средами разработки. Разработчику необходимо скачать vagrant и виртуальную машину, а всю работу(переброска портов, настройка памяти, синхронизация и скачивание зависимостей) выполнит Vagrant при помощи ansible, Chef, ... Несмотря на то что Vagrant --- бесплатное ПО, на территории РФ придется использовать http proxy или VPN. В настоящее время настраивается работа для virtualbox и vmware. Несмотря на то что ipmininet поддерживает Vagrant, ipmininet box занимает в три раза больше места, а мы хотим избавиться от лишних зависимостей + скачивание 2 гб через прокси было бы тем еще удовольствием.

## [Генератор установщиков](https://github.com/hashicorp/vagrant-installers)
## [Документация](https://developer.hashicorp.com/vagrant/docs)

### Windows
Советую использовать для Windows virtualbox, так как регистрация для получения vmware займет в 10 раз больше времени чем вся работа с virtualbox.
Если вы используете http proxy, PowerShell:
```
   $env:VAGRANT_HTTP_PROXY="http://login:password@ip:port"
   $env:VAGRANT_HTTPS_PROXY="http://login:password@ip:port"
```

1. Установите Vagrant по ссылке https://developer.hashicorp.com/vagrant/downloads
2. Добавьте box bento/ubuntu-22.04.
   - Если вы используете http proxy. При скачивании выберите нужную виртуальную машину:
   ```
   vagrant box add bento/ubuntu-22.04
   ```
   - Если вы cкачиваете из [Vagrant clound](https://app.vagrantup.com/bento/boxes/ubuntu-22.04), то выберите нужного provider:
   ```
   vagrant box add bento/ubuntu-22.04  file:///d:/path/to/file.box
   ```
Убедитесь, что установили box
```
vagrant box list
```
3. Если у вас Virtualbox, пропустите этот шаг, иначе [проследуйте этому руководству](https://developer.hashicorp.com/vagrant/docs/providers/vmware/installation).
4. Склонируйте этот репозиторий и сделайте vagrant up в зависимости от того какой вм вы пользуетесь:
   - virtualbox
     ```
     git clone && vagrant up vbox
     ```
   - vmware
     ```
     git clone && vagrant up vmware
     ```
5. Так как vboxfs не в состоянии обеспечить нормальную синхронизацию shared folder, для этого используется протокол [SMB](https://ru.wikipedia.org/wiki/Server_Message_Block). В связи с этим, не получилось полностью автоматизировать процесс, так как windows UAC запросит у вас имя пользователя и пароль (однако, пройдет совсем небольшое количество времени с vagrant up).
6. Рабочая директория синхронизирована с вм, порты переброшены(но стандартный 5000 Flask изменен на 8000, чтобы вы могли на хосте запускать Flask на 5000), все завимости установлены. Таким образом, можете работать на своем хосте, используя привычную IDE, браузер и т.д., пока в вм развернут miminet.
7. Обратите внимание, что если у вас Windows 11 и provider vmware, то вам нужна VMware Workstation 17.
8. Процесс скачивания может показаться неприятным, но в итоге все разворачивается в git clone && vagrant up
   
### Intel macos, linux(ubuntu, fedora, ....)
1. Если у вас поддерживается Virtualbox, пройдите все шаги для windows, используя
   ```
   export VAGRANT_HTTP_PROXY="http://login:password@ip:port"
   export VAGRANT_HTTPS_PROXY="http://login:password@ip:port"
   ```
2. Отличие только будет в том, что для macos  используется NFS вместо SMB. Для его работы с virtualbox необходимо создать частную сеть и выдать вм в ней ip. Это можно сделать прямо в Vagrantfile с помощью DHCP, но в таком случае не получится заранее узнать ip и при монтировании могут возникнуть ошибки, связанные с блокировкой NFS firewall'ом. Поэтому с помощью dhcpd.conf заранее выбирается свободный ip из подсети 192.168.56.x/24(так как хост для virtualbox имеет значение 192.168.56.1 по умолчанию) и происходит настройка firewall на разрешение NFS конкретно с этого ip (пока что написано только для Ubuntu, возможно, вам придется самим настроить firewall на своей системе для NFS)
3. При использовании NFS у вас опять будет запрошен пароль, [но можно избежать его ввода](https://developer.hashicorp.com/vagrant/docs/synced-folders/nfs#root-privilege-requirement), отредактировав /etc/sudoers:
   - macos
     ```
     Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
     Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
     Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
     %admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE
     ```
    - linux
      ```
      Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/vagrant-exports
      Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/vagrant-exports /etc/exports
      Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
      Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
      Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
      %sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
      ```

### Arm64 Macos
Пройдите все круги ада из инструкции для Windows/vmware или пройдите [рукводство](https://developer.hashicorp.com/vagrant/docs/providers/vmware/installation).
```
git clone && vagrant up vmware
```

### Итоги

После vargant up у Вас будет экземпляр виртуальной машины Ubuntu со скачанными mininet, python3-pip, python3-venv, ipmininet и локально развернутым miminet.

Преимущества:
1. Решение вполне универсальное, так как Vagrant поддерживает Virtualbox и vmware(то есть вы сможете много где развернуть miminet).
2. Это все еще лучше чем просто поставить виртуальную машину, потому что при использовании Vagrant можно максимально автоматизировать процесс развертывания с помощью конфигурационных файлов и сильно упростить процесс настройки для разработчика(указать переброску портов, настроить shared folder для конфигурации с хостом, автоматический обмен файлами с сервером через SFTP при помощи одной команды и прочее).
3. Локальное развертывание mininet в пару команд.
4. Идеологически это подходит mininet куда больше чем Docker, так как mininet и ipmininet требуется доступ к routing tables хоста, настройкам интерфейса /etc/network/interfaces и т.д., то есть просто так засунуть miminet в контейнер со всеми зависимостями не получится(надо давать определенные разрешения(ему не хватит CAP_ALL) или делать контейнер привилегированным).

   
