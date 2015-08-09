#!/bin/bash
# a script to install server dependencies

# provide messaging colors for output to console
txtbld=$(tput bold)             # Bold
bldgrn=$(tput setaf 2) #  green
bldred=${txtbld}$(tput setaf 1) #  red
txtreset=$(tput sgr0)
elmslnecho(){
  echo "${bldgrn}$1${txtreset}"
}
elmslnwarn(){
  echo "${bldred}$1${txtreset}"
}
# Define seconds timestamp
timestamp(){
  date +"%s"
}
start="$(timestamp)"
# get the epel and remi repo listings so we can get additional packages like mcrypt
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm
# make sure we're up to date w/ the remi repos
yes | yum update
# using yum to install the main packages
yes | yum -y install patch git nano gcc make mysql mysql-server httpd php php-gd php-xml php-pdo php-mbstring php-mysql php-pear php-devel php-pecl-ssh2 php-pecl-apc php-mcrypt*

yes | yum groupinstall 'Development Tools'
# using pecl to install uploadprogress
pecl channel-update pecl.php.net
# uploadprogress to get rid of that warning
pecl install uploadprogress

# adding uploadprogresss to php conf files
touch /etc/php.d/uploadprogress.ini
echo extension=uploadprogress.so > /etc/php.d/uploadprogress.ini

# set httpd_can_sendmail so drupal mails go out
setsebool -P httpd_can_sendmail on
# start mysql to ensure that it is running
/etc/init.d/mysqld restart

#install varnish
rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-3.0.el6.rpm
yum install varnish -y

sed -i 's/VARNISH_LISTEN_PORT=6081/VARNISH_LISTEN_PORT=80/g' /etc/sysconfig/varnish
sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
cat /dev/null > /etc/varnish/default.vcl
cat /var/www/elmsln/docs/varnish.txt > /etc/varnish/default.vcl

# make an admin group
groupadd admin
# run the handsfree installer that's the same for all deployments
# kick off hands free deployment
bash /var/www/elmsln/scripts/install/handsfree/handsfree-install.sh 1 $1 $2 $3 $3 $3 data- $4 $5 $5 admin $6
cd $HOME
source .bashrc
end="$(timestamp)"
elmslnecho "This took $(expr $end - $start) seconds to complete the whole thing!"
