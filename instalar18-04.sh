#!/bin/bash
locale-gen pt_BR.UTF-8
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8
#dpkg-reconfigure locales
mkdir -p /usr/local/eox/
mkdir -p /usr/local/eox/src/
mkdir -p /usr/local/eox/programas
mkdir -p /var/eox/log/
mkdir -p /var/eox/log/freeswitch/
chmod -R 777 /var/eox/log/freeswitch/
mkdir -p /var/eox/backup/
mkdir -p /var/eox/sounds/
chmod -R 777 /var/eox/backup/
mkdir -p /var/eox/blacklist/
echo '' > /var/eox/blacklist/ativo.txt
echo '' > /var/eox/blacklist/receptivo.txt
chmod -R 777 /var/eox/blacklist/
mkdir -p /var/eox/recordings/
chmod -R 777 /var/eox/recordings/
#Dependencias
apt-get update
apt-get install git-core subversion build-essential autoconf automake libtool libncurses5 libncurses5-dev make libjpeg-dev \
libcurl4-openssl-dev libexpat1-dev  libtiff5-dev libx11-dev unixodbc-dev libssl-dev zlib1g-dev  \
libasound2-dev libogg-dev libvorbis-dev libperl-dev libgdbm-dev libdb-dev python-dev uuid-dev libpq-dev sqlite3 libsqlite3-dev \
libpcre3-dev speex libspeexdsp-dev libldns-dev libedit-dev yasm nasm libopus-dev libsndfile-dev unzip dialog libmp3lame-dev libshout3-dev libmpg123-dev tzdata -y

#Conf
cd /usr/local/eox/
git clone https://instalador:eoxvocallcenter@git.eox.com.br/eox/vocallcenter.git
chmod -R 777 /usr/local/eox/vocallcenter/
cd /usr/local/eox/vocallcenter/
git config --global core.fileMode false
git config core.fileMode false
ln -s /var/eox/recordings/ /usr/local/eox/vocallcenter/agent/recordings
cp /usr/local/eox/vocallcenter/conf/config.ini /usr/local/eox/config.ini
cp -Rap /usr/local/eox/vocallcenter/conf/sounds/* /var/eox/sounds/
chmod -R 777 /var/eox/sounds/
#Apache
apt-get install apache2 apache2-utils -y
a2enmod ssl
a2enmod rewrite
cp -Rap /usr/local/eox/vocallcenter/conf/apache2/* /etc/apache2/
sudo a2ensite default-ssl
#PHP
apt-get install php php-pgsql libapache2-mod-php -y
#Postgres
apt-get install postgresql libpq5 postgresql-10 postgresql-client-10 postgresql-client-common postgresql-contrib odbc-postgresql -y
cp /usr/local/eox/vocallcenter/conf/odbc.ini /etc/odbc.ini
cp /usr/local/eox/vocallcenter/conf/odbcinst.ini /etc/odbcinst.ini
cat < /usr/local/eox/vocallcenter/conf/pg_hba.conf > /etc/postgresql/10/main/pg_hba.conf
sudo -i -u postgres psql < /usr/local/eox/vocallcenter/databasescripts/criar_data_base.sql
sudo -i -u postgres psql vocallcenter < /usr/local/eox/vocallcenter/databasescripts/vocallcenter.sql
sudo -i -u postgres psql vocallcenter < /usr/local/eox/vocallcenter/databasescripts/dados_basicos.sql

# OpenSSL

cd  /usr/local/eox/src/
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2g.tar.gz
tar zxvf openssl-1.0.2g.tar.gz 
cd openssl-1.0.2g
./config shared --prefix=/usr/local/eox/programas/openssl-1.0.2g
make && make install


#Freeswitch
cd /usr/local/eox/src/
git clone https://instalador:eoxvocallcenter@git.eox.com.br/eox/freeswitch2.git freeswitch
cd freeswitch/
autoreconf -vfi
sed '$d' -i configure_freeswitch.sh
echo '--prefix=/usr/local/eox/programas/freeswitch \' >> configure_freeswitch.sh
echo "CFLAGS="-I/usr/local/eox/programas/openssl-1.0.2g/include" LDFLAGS="-L/usr/local/eox/programas/openssl-1.0.2g/lib"" >> configure_freeswitch.sh
./configure_freeswitch.sh
make && make install
cp freeswitch.sh /etc/init.d/freeswitch
cd mod_bcg729-master/
make && make install
adduser --disabled-password  --quiet --system --home /usr/local/eox/programas/freeswitch --gecos "FreeSWITCH Voice Platform" --ingroup daemon freeswitch
chown -R freeswitch:daemon /usr/local/eox/programas/freeswitch/ 
chmod -R o-rwx /usr/local/eox/programas/freeswitch/
ln -s /usr/local/eox/programas/freeswitch/etc/freeswitch/ /usr/local/eox/programas/freeswitch/conf
ln -s /usr/local/eox/programas/freeswitch/bin/fs_cli /usr/local/bin/fs_cli
chmod -R 777 /usr/local/eox/programas/freeswitch
echo "/var/eox/log/freeswitch/core.%e.%p.%h.%t" > /proc/sys/kernel/core_pattern
echo 2 > /proc/sys/fs/suid_dumpable
#Servicos PHP
add-apt-repository ppa:ondrej/php -y
apt-get update
apt-get install php7.0 php5.6 php5.6-pgsql php-gettext php5.6-mbstring php-mbstring php7.0-mbstring php-xdebug libapache2-mod-php5.6 libapache2-mod-php7.0 php5.6-zip php5.6-gd php5.6-xml php5.6-curl -y
a2dismod php7.0
a2dismod php7.2
a2enmod php5.6
service apache2 restart
update-alternatives --set php /usr/bin/php5.6
cp /usr/local/eox/vocallcenter/conf/php/5.6/cli/php.ini /etc/php/5.6/cli/
cp /usr/local/eox/vocallcenter/conf/php/5.6/apache2/php.ini /etc/php/5.6/apache2/
cp /usr/local/eox/vocallcenter/conf/ESL.so /usr/lib/php/20131226/
mkdir -p /var/eox/log/vocallsocket/
ln -s /usr/local/eox/vocallcenter/initscripts_new/vocallsocket /etc/init.d/vocallsocket
systemctl enable vocallsocket
update-rc.d vocallsocket start 30  2 3 4 5 . stop 70 0 1 6 .
mkdir -p /var/eox/log/vocallintegration/
ln -s /usr/local/eox/vocallcenter/initscripts_new/vocallintegration /etc/init.d/vocallintegration
systemctl enable vocallintegration
mkdir -p /var/eox/log/vocallhtml5/
ln -s /usr/local/eox/vocallcenter/initscripts_new/vocallhtml5 /etc/init.d/vocallhtml5
systemctl enable vocallhtml5
update-rc.d vocallhtml5 start 30  2 3 4 5 . stop 70 0 1 6 .
reboot
