#!/bin/bash
echo Escreve a password do root para entrar na base de dados
read rootpass

echo Escreve a rede para aceder à base de dados, Exemplo: 192.168.34.%
read netdb

echo Escreve o username da base de dados, Exemplo: agora_db
read userdb

echo Escreve a password do utilizador na resposta anterior
read passdb

echo Escreve o IP do servidor
read bindaddress

echo Escreve a comunidade de SNMP
read snmpcommunity






#apt install packages
echo Updating and installing packages

apt update
apt install acl curl fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php-cli php-curl php-fpm php-gd php-gmp php-json php-mbstring php-mysql php-snmp php-xml php-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools python3-systemd python3-pip -y






#add librenms user
echo A adicionar e instalar o librenms...

useradd librenms -d /opt/librenms -M -r -s "$(which bash)"






#install librenms through github
cd /opt && git clone https://github.com/librenms/librenms.git

echo "User Librenms adicionado e instalado, a dar grep dos resultados (Se estiver em branco é porque algo deu errado):"
echo "$(ls /opt/ | grep librenms)"
echo "$(cat /etc/passwd | grep librenms)"






#setting permissions
echo "A alterar as permissões da pasta"

chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

echo "Permissioes alteradas, a dar grep dos resultados (Se estiver em branco é porque algo deu errado):"
echo "$(ls /opt/librenms)"






#installing dependencies
echo A instalar as dependecias e o composer

su - librenms -c './scripts/composer_wrapper.php install'
wget https://getcomposer.org/composer-stable.phar
mv composer-stable.phar /usr/bin/composer
chmod +x /usr/bin/composer






#set timezone
echo A mudar a timezone

timezone="date.timezone = Europe/Lisbon"
sed -i "s@;date.timezone =@${timezone}@g" /etc/php/8.1/fpm/php.ini
sed -i "s@;date.timezone =@${timezone}@g"  /etc/php/8.1/cli/php.ini
timedatectl set-timezone Europe/Lisbon

echo "Timezone alterada, a dar grep dos resultados:"
echo "$(cat /etc/php/8.1/fpm/php.ini | grep Europe/Lisbon)"
echo "$(cat /etc/php/8.1/cli/php.ini | grep Europe/Lisbon)"






#Configure MariaDB
echo A configurar MariaDB

sed -i "10iinnodb_file_per_table=1" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "11ilower_case_table_names=0" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "s/127.0.0.1/${bindaddress}/g" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl enable mariadb
systemctl restart mariadb


mysql -u root -p$rootpass -Bse "CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$userdb'@'$netdb' IDENTIFIED BY '$passdb';
GRANT ALL PRIVILEGES ON librenms.* TO '$userdb'@'$netdb'"

echo "MariaDB configurada, a dar grep do resultado:"
echo "User:"
echo "$(mysql -u root -p$rootpass -Be "SELECT host, user FROM mysql.user;SHOW databases;")"
echo ""
echo "Database:"
echo "$(mysql -u root -p$rootpass -Be "SHOW databases;")"
echo "$(cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep "innodb_file_per_table=1")"
echo "$(cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep "lower_case_table_names=0")"
echo "$(cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep $bindaddress)"



#Configure PHP-FPM
echo A configurar PHP-FPM

cp /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/librenms.conf
sed -i "4s/\[www\]/[librenms]/g" /etc/php/8.1/fpm/pool.d/librenms.conf
sed -i "s/user = www-data/user = librenms/g" /etc/php/8.1/fpm/pool.d/librenms.conf
sed -i "s/group = www-data/group = librenms/g" /etc/php/8.1/fpm/pool.d/librenms.conf
sed -i "s/listen = \/run\/php\/php8.1-fpm.sock/listen = \/run\/php-fpm-librenms.sock/g" /etc/php/8.1/fpm/pool.d/librenms.conf

echo "Configurado, a dar grep dos resultados:"
echo "$(cat /etc/php/8.1/fpm/pool.d/librenms.conf | grep "\[librenms\]")"
echo "$(cat /etc/php/8.1/fpm/pool.d/librenms.conf | grep "user = librenms")"
echo "$(cat /etc/php/8.1/fpm/pool.d/librenms.conf | grep "group = librenms")"
echo "$(cat /etc/php/8.1/fpm/pool.d/librenms.conf | grep "listen = /run/php-fpm-librenms.sock")"






#Configure Web Server
echo A configurar Web Server

tee -a /etc/nginx/conf.d/librenms.conf << END
server {
 listen      80;
 server_name $bindaddress;
 root        /opt/librenms/html;
 index       index.php;

 charset utf-8;
 gzip on;
 gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
 location / {
  try_files $uri $uri/ /index.php?$query_string;
 }
 location ~ [^/]\.php(/|$) {
  fastcgi_pass unix:/run/php-fpm-librenms.sock;
  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  include fastcgi.conf;
 }
 location ~ /\.(?!well-known).* {
  deny all;
 }
}

END

rm /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl restart php8.1-fpm

echo "WebServer configurado"







#Enable lnms command completion
echo Ativando lnms command completion

ln -s /opt/librenms/lnms /usr/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

echo "Concluido, a dar grep do resultado:"
echo "$(ls /etc/bash_completion.d/ | grep "lnms-completion.bash")"






#configure snmpd
echo Configurando snmpd

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf
sed -i "s/RANDOMSTRINGGOESHERE/${snmpcommunity}/g" /etc/snmp/snmpd.conf
curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable snmpd
systemctl restart snmpd

echo "snmpd configurado, a dar grep do resultado:"
echo "$(cat /etc/snmp/snmpd.conf | grep $snmpcommunity)"






#Cron Job
#echo A ativar cronjob

#cp /opt/librenms/dist/librenms.cron /etc/cron.d/librenms

#echo "CronJob ativado, a dar grep do resultado"
#echo "$(ls /etc/cron.d | grep librenms)"






#Enable the scheduler
echo "A ativar o scheduler e criar config.php"

cp /opt/librenms/dist/librenms-scheduler.service /opt/librenms/dist/librenms-scheduler.timer /etc/systemd/system/
systemctl enable librenms-scheduler.timer
systemctl start librenms-scheduler.timer
cp /opt/librenms/config.php.default /opt/librenms/config.php

echo "Scheduler ativado e config criado, a dar grep do resultado:"
echo "$(ls /etc/systemd/system/ | grep librenms-scheduler.service && ls /etc/systemd/system/ | grep librenms-scheduler.timer && ls /opt/librenms | grep config.php)"






#Dispatcher Service
echo Ativando o Dispatcher Service

su - librenms -c 'pip3 install -r requirements.txt'
cp /opt/librenms/misc/librenms.service /etc/systemd/system/librenms.service && systemctl enable --now librenms.service






#Copy logrotate config
echo A copiar o logrotate config

cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

echo "Logrotate copiado, a dar grep do resultado:"
echo "$(ls /etc/logrotate.d/ | grep librenms)"





#Web Installer
chown librenms:librenms /opt/librenms/config.php

#Alterar o .env
sed -i "s/#DB_HOST=/DB_HOST=${bindaddress}/g" /opt/librenms/.env
sed -i "s/#DB_DATABASE=/DB_DATABASE=librenms/g" /opt/librenms/.env
sed -i "s/#DB_USERNAME=/DB_USERNAME=${userdb}/g" /opt/librenms/.env
sed -i "s/#DB_PASSWORD=/DB_PASSWORD=${passdb}/g" /opt/librenms/.env
