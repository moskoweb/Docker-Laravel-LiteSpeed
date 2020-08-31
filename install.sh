#!/bin/bash

if [ -n "$DB_NAME" ]; then
    echo "MySQL | Create database"
    mysql --no-defaults -h $DB_HOST --port $DB_PORT -u $DB_USER -p$DB_PASS -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
fi

echo "Composer | Install"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

echo "Node | Install"
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs

echo "PHP | Ini Set Values"
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $PHP_INI_MAXFILE_SIZE/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
sed -i "s/post_max_size = 8M/post_max_size = $PHP_INI_MAXFILE_SIZE/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = $PHP_INI_EXECUTION_TIME/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
sed -i "s/max_input_time = 60/max_input_time = $PHP_INI_EXECUTION_TIME/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
sed -i "s/memory_limit = 128M/memory_limit = $PHP_INI_MEMORY_LIMIT/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
sed -i "s/;max_input_vars = 1000/max_input_vars = 3000/g" /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini

echo "Laravel | Cron Job Set"
crontab -l > tempcron
echo "# Laravel Cron Job" >> tempcron
echo "* * * * * cd /var/www/vhosts/localhost/html/ && php artisan schedule:run >> /dev/null 2>&1" >> tempcron
echo "0 * * * * chown -R lsadm:lsadm /var/www/vhosts/localhost/html/.* >> /dev/null 2>&1" >> tempcron
echo "0 * * * * chmod -R g+rw /var/www/vhosts/localhost/html/.* >> /dev/null 2>&1" >> tempcron
echo "0 * * * * chown -R lsadm:lsadm /var/www/vhosts/localhost/html/* >> /dev/null 2>&1" >> tempcron
echo "0 * * * * chmod -R g+rw /var/www/vhosts/localhost/html/* >> /dev/null 2>&1" >> tempcron
crontab tempcron
rm tempcron

cd /var/www/vhosts/localhost/html

if [ -n "$LARAVEL_INSTALL" ]; then
    echo "Laravel | Install"
    rm -rf *
    composer create-project --prefer-dist laravel/laravel .
else
    echo "PHP | Install"
    mkdir public
    echo "<h1>Hello World</h1>" >> public/index.php
fi

if [ -e ".env" ]; then
    sed -i "s/APP_ENV=local/APP_ENV=production/g" .env
    sed -i "s/APP_DEBUG=true/APP_DEBUG=false/g" .env
    
    if [ -n "$VIRTUAL_HOST" ]; then
        sed -i "s/APP_URL=http:\/\/localhost/APP_URL=http:\/\/$VIRTUAL_HOST/g" .env
    fi
    
    if [ -n "$DB_NAME" ]; then
        sed -i "s/DB_HOST=127.0.0.1/DB_HOST=$DB_HOST/g" .env
        sed -i "s/DB_PORT=3306/DB_PORT=$DB_PORT/g" .env
        sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/g" .env
        sed -i "s/DB_USERNAME=root/DB_USERNAME=$DB_USER/g" .env
        sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DB_PASS/g" .env
    fi
fi

mv /var/www/vhosts/localhost/.htaccess /var/www/vhosts/localhost/html/.htaccess

chown -R lsadm:lsadm /var/www/vhosts/localhost/html/.*
chmod -R g+rw /var/www/vhosts/localhost/html/.*
chown -R lsadm:lsadm /var/www/vhosts/localhost/html/*
chmod -R g+rw /var/www/vhosts/localhost/html/*

echo "LiteSpeed | Restart"
/usr/local/lsws/bin/lswsctrl restart

echo "Laravel | Install Completed"
