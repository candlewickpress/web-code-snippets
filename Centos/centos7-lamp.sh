#!/usr/bin/env bash

# This is designed to get a CentOS 7 system up and running
# from absolutely nothing. It will install the LAMP stack
# as well as RVM and Phusion Passenger

# Run this as root

yum update

echo '>> Creating wpgwebadmin user'

adduser wpgwebadmin
passwd wpgwebadmin
gpasswd -a wpgwebadmin wheel

# sed -i -e 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
systemctl reload ssh

echo '>> Starting firewall'

systemctl start firewalld
firewall-cmd --permanent --add-service=ssh

echo '>> Setting timezone to America/New_York and installing NTP'

timedatectl set-timezone America/New_York
yum install -y ntp
systemctl start ntpd
systemctl enable ntpd

echo '>> Configuring swap'

fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

echo '>> Installing Apache, MariaDB, and PHP'

yum install -y httpd
systemctl start httpd.service
systemctl enable httpd.service

yum install -y mariadb-server mariadb
systemctl start mariadb
mysql_secure_installation
systemctl enable mariadb.service

yum install -y php php-mysql
systemctl restart httpd.service

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

echo '>> Installing RVM and Ruby'

yum install -y curl gpg gcc gcc-c++ make
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

sudo -u eph -s #You HAVE to run the RVM as non-root, sudo not withstanding

curl -sSL https://get.rvm.io | sudo bash -s stable

exit

usermod -a -G rvm eph
if grep -q secure_path /etc/sudoers; then sh -c "echo export rvmsudo_secure_path=1 >> /etc/profile.d/rvm_secure_path.sh" && echo Environment variable installed; fi

sudo -u eph -s

rvm install ruby
rvm --default use ruby
gem install bundler --no-rdoc --no-ri

exit

yum install -y epel-release yum-utils
yum-config-manager --enable epel
yum install -y nodejs npm pygpgme curl

curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo

yum install -y mod_passenger

systemctl restart httpd

echo '>> Done! >>'