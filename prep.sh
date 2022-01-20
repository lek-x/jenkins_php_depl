#!/bin/bash

sudo apt purge -y apache2
echo "Setting Up jenkins worker"

read -p 'Input pass for DB symfony and remember it: ' sy
#sy='Tsert1293@' ## edit mysql pass directly

echo "Installing PHP +  Modules"



php=("php8.1" "php8.1-mbstring"  "php8.1-xml" "php8.1-zip" "php8.1-sqlite3" "php8.1-curl" "php8.1-fpm" "php8.1-common" \
         "php8.1-mysql" "php8.1-gmp" "php8.1-intl" "php8.1-xmlrpc" "php8.1-gd" \
         "php8.1-bcmath" "php8.1-soap" "php8.1-ldap" "php8.1-imap" "php8.1-cli" "wget" "unzip")

### Intsalling PHP + Modules
for i in ${php[*]}; do
     sudo apt install -y  $i
done


sed -i 's/listen = \/run\/php\/php8.1-fpm.sock/listen = \/var\/run\/php\/php8.1-fpm.sock/g' /etc/php/8.1/fpm/pool.d/www.conf


### Intsalling MYSQL
echo "Installing mysql server"
sudo apt install -y mysql-server

clear

echo "Starting MYSQL secure installing"
sleep 3
sudo mysql_secure_installation

echo "Setting up DB"
sleep 2
sudo mysql -h localhost -u root  -p   << EOF
CREATE USER IF NOT EXISTS 'symfony'@'localhost' IDENTIFIED  BY '$sy';
CREATE DATABASE IF NOT EXISTS symfony CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL PRIVILEGES ON symfony.* TO 'symfony'@'localhost';
EOF

### Intsalling composer
echo "Install composer"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"



### Intsalling NGINX
echo "Install NGINX"

sudo apt install -y nginx

sudo echo '''
server {
    server_name _;
    listen 80 default_server;
    root /var/www/mysite/public;

    location / {
        # try to serve file directly, fallback to rewrite
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTPS off;
        internal;
    }
    location ~ \.php$ {
                return 404;
    }
    error_log /var/log/nginx/project_error.log;
    access_log /var/log/nginx/project_access.log;
}
'''  > /etc/nginx/sites-available/symfony.conf

sudo ln -sf /etc/nginx/sites-available/symfony.conf  /etc/nginx/sites-enabled/symfony.conf
sudo rm -f /etc/nginx/nginx.conf

sudo echo '''
user www-data;
worker_processes 2;
worker_cpu_affinity  auto;
pid /run/nginx.pid;

events {
        worker_connections 256;

}

http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        gzip on;
        gzip_disable "msie6";

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*.conf;
}
''' > /etc/nginx/nginx.conf

clear
echo "Remember your pass to symfony DB: $sy"
sleep 2

### Creating dir for symfony .env, inserting auth string
mkdir /home/jenkins/project_sys

cat <<EOF > /home/jenkins/project_sys/.env
APP_ENV=dev
APP_SECRET=2ca64f8d83b9e89f5f19d672841d6bb8
#TRUSTED_PROXIES=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
#TRUSTED_HOSTS=\'^OC\(localhost|example.com\)$\'
DATABASE_URL=mysql://symfony:$sy@127.0.0.1:3306/symfony
EOF


sudo service nginx restart 
sudo service php8.1-fpm restart