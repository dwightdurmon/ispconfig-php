#!/bin/bash

read -p "Enter PHP 7.1 Version (or blank to skip): " php71
read -p "Enter PHP 7.2 Version (or blank to skip): " php72
read -p "Enter PHP 5.6 Version (or blank to skip): " php56

echo "Building with PHP versions: "
echo "Version: [${php71}]"
echo "Version: [${php72}]"
echo "Version: [${php56}]"

read -p "Press Enter to begin or CTRL-C to quit"

echo "Install Prerequisites"

apt-get install -y build-essential nano

apt-get install -y libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dev libmcrypt-dev \
libssl-dev libc-client2007e libc-client2007e-dev libxml2-dev libbz2-dev \
libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libkrb5-dev \
libpq-dev libxml2-dev libxslt1-dev

ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a

cd /usr/include
ln -s x86_64-linux-gnu/curl

if [[ "$php71" != "" ]]; then
    echo "Installing PHP ${php71} to /opt/${php71}"
    mkdir -p /opt/php-${php71}
    mkdir /usr/local/src/php${php71}-build
    cd /usr/local/src/php${php71}-build
    wget http://de2.php.net/get/php-${php71}.tar.bz2/from/this/mirror -O php-${php71}.tar.bz2
    tar jxf php-${php71}.tar.bz2
    cd php-${php71}/

    ./configure --prefix=/opt/php-${php71} --with-pdo-pgsql --with-zlib-dir \
    --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr \
    --enable-soap --enable-calendar --with-curl --with-mcrypt \
    --with-zlib --with-gd --with-pgsql --disable-rpath \
    --enable-inline-optimization --with-bz2 --with-zlib \
    --enable-sockets --enable-sysvsem --enable-sysvshm \
    --enable-pcntl --enable-mbregex --enable-exif \
    --enable-bcmath --with-mhash --enable-zip --with-pcre-regex \
    --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock \
    --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf \
    --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data \
    --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --with-imap \
    --with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc \
    --with-xsl --enable-opcache --enable-fpm

    make
    make install

    cp /usr/local/src/php${php71}-build/php-${php71}/php.ini-production /opt/php-${php71}/lib/php.ini
    cp /opt/php-${php71}/etc/php-fpm.conf.default /opt/php-${php71}/etc/php-fpm.conf
    cp /opt/php-${php71}/etc/php-fpm.d/www.conf.default /opt/php-${php71}/etc/php-fpm.d/www.conf

    echo "Please update /opt/php-${php71}/etc/php-fpm.d/www.conf"
    echo "Uncomment the 'listen' line if needed (remove the ;)"
    echo "and update the port."
    read -p "Press Enter to continue"

    vi /opt/php-${php71}/etc/php-fpm.d/www.conf

    echo "Setting up Service"
    cat >/lib/systemd/system/php-${php71}-fpm.service <<EOF

[Unit]
Description=The PHP ${php71} FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=/opt/php-${php71}/var/run/php-fpm.pid
ExecStart=/opt/php-${php71}/sbin/php-fpm --nodaemonize --fpm-config /opt/php-${php71}/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

    echo "Please check the service file: /lib/systemd/system/php-${php71}-fpm.service"
    read -p "Press Enter to continue"
    vi /lib/systemd/system/php-${php71}-fpm.service

    systemctl enable php-${php71}-fpm.service
    systemctl daemon-reload
    systemctl start php-${php71}-fpm.service

    echo "Enabling Zend OPcache"
    echo "zend_extension=opcache.so" >> /opt/php-${php71}/lib/php.ini

    echo "Building Memcache"
    apt-get install libmemcached-dev
    mkdir /usr/local/src/php${php71}-build/php-memcache
    cd /usr/local/src/php${php71}-build/php-memcache
    wget https://github.com/php-memcached-dev/php-memcached/archive/php7.zip
    unzip php7.zip
    cd php-memcached-php7

    /opt/php-${php71}/bin/phpize

    ./configure --with-php-config=/opt/php-${php71}/bin/php-config
    make
    make install

    echo "Enabling Memcached"
    echo "extension=memcached.so" >> /opt/php-${php71}/lib/php.ini

    echo "Building Xdebug"
    cd /opt/php-${php71}/etc
    pecl -C ./pear.conf update-channels
    pecl -C ./pear.conf install xdebug

    echo "Enabling Xdebug"
    echo "zend_extension=/opt/php-${php71}/lib/php/extensions/no-debug-non-zts-20160303/xdebug.so" >> /opt/php-${php71}/lib/php.ini

    echo "Starting PHP ${php71} FPM service"
    systemctl start php-${php71}-fpm.service

    echo "Checking PHP Version"
    cd /opt/php-${php71}/bin
    ./php --version

    read -p "Press Enter to continue"

    echo "ISPConfig Settings"
    echo "-> Name Tab"
    echo "PHP Name: PHP ${php71}"
    echo "-> FastCGI Settings Tab"
    echo "Path to the PHP FastCGI binary: /opt/php-${php71}/bin/php-cgi"
    echo "Path to the php.ini directory: /opt/php-${php71}/lib"
    echo "-> PHP-FPM Settings tab"
    echo "Path to the PHP-FPM init script: php-${php71}-fpm"
    echo "Path to the php.ini directory: /opt/php-${php71}/lib"
    echo "Path to the PHP-FPM pool directory: /opt/php-${php71}1/etc/php-fpm.d"
fi

read -p "Press Enter to continue to PHP ${php72}"

echo "========================================================="


if [[ "$php72" != "" ]]; then
    echo "Installing PHP ${php71} to /opt/${php71}"
    mkdir -p /opt/php-${php72}
    mkdir /usr/local/src/php${php72}-build
    cd /usr/local/src/php${php72}-build
    wget http://de2.php.net/get/php-${php72}.tar.bz2/from/this/mirror -O php-${php72}.tar.bz2
    tar jxf php-${php72}.tar.bz2

    cd php-${php72}/

    ./configure --prefix=/opt/php-${php72} --with-pdo-pgsql --with-zlib-dir --with-freetype-dir \
    --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl \
    --with-zlib --with-gd --with-pgsql --disable-rpath --enable-inline-optimization \
    --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl \
    --enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex \
    --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock --with-jpeg-dir=/usr \
    --with-png-dir=/usr --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu \
    --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl \
    --enable-opcache --enable-fpm

    make

    make install

    cp /usr/local/src/php${php72}-build/php-${php72}/php.ini-production /opt/php-${php72}/lib/php.ini

    cp /opt/php-${php72}/etc/php-fpm.conf.default /opt/php-${php72}/etc/php-fpm.conf

    cp /opt/php-${php72}/etc/php-fpm.d/www.conf.default /opt/php-${php72}/etc/php-fpm.d/www.conf

    echo "Please update /opt/php-${php72}/etc/php-fpm.conf"
    echo "Uncomment the pid line if needed."
    read -p "Press Enter to continue"
    vi /opt/php-${php72}/etc/php-fpm.conf
    pid = run/php-fpm.pid


    echo "Please update /opt/php-${php72}/etc/php-fpm.d/www.conf"
    echo "Uncomment the 'listen' line if needed (remove the ;)"
    echo "and update the port."
    read -p "Press Enter to continue"
    vi /opt/php-${php72}/etc/php-fpm.d/www.conf


    echo "Setting up Service"
    cat >>/lib/systemd/system/php-${php72}-fpm.service << EOF 
[Unit]
Description=The PHP ${php72} FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=/opt/php-${php72}/var/run/php-fpm.pid
ExecStart=/opt/php-${php72}/sbin/php-fpm --nodaemonize --fpm-config /opt/php-${php72}/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

    echo "Please check the service file: /lib/systemd/system/php-${php72}-fpm.service"
    read -p "Press Enter to continue"
    vi /lib/systemd/system/php-${php72}-fpm.service

    systemctl enable php-${php72}-fpm.service
    systemctl daemon-reload
    systemctl start php-${php72}-fpm.service

    echo "Enabling Zend OPcache"
    echo "zend_extension=opcache.so" >> /opt/php-${php72}/lib/php.ini


    echo "Building Memcache"
    apt-get install libmemcached-dev
    mkdir /usr/local/src/php${php72}-build/php-memcache
    cd /usr/local/src/php${php72}-build/php-memcache
    wget https://github.com/php-memcached-dev/php-memcached/archive/php7.zip
    unzip php7.zip
    cd php-memcached-php7

    /opt/php-${php72}/bin/phpize

    ./configure --with-php-config=/opt/php-${php72}/bin/php-config
    make
    make install

    echo "Enabling Memcached"
    echo "extension=memcached.so" /opt/php-${php72}/lib/php.ini


    echo "Building Xdebug"
    cd /opt/php-${php72}/etc
    pecl -C ./pear.conf update-channels
    pecl -C ./pear.conf install xdebug

    echo "Enabling Xdebug"
    echo "zend_extension=/opt/php-${php72}/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so" /opt/php-${php72}/lib/php.ini

    echo "Starting PHP ${php71} FPM service"
    systemctl start php-${php72}-fpm.service

    echo "Checking PHP Version"
    cd /opt/php-${php72}/bin
    ./php --version

    read -p "Press Enter to continue"

    echo "ISPConfig Settings"
    echo "-> Name Tab"
    echo "PHP Name: PHP ${php72}"
    echo "-> FastCGI Settings Tab"
    echo "Path to the PHP FastCGI binary: /opt/php-${php72}/bin/php-cgi"
    echo "Path to the php.ini directory: /opt/php-${php72}/lib"
    echo "-> PHP-FPM Settings tab"
    echo "Path to the PHP-FPM init script: php-${php72}-fpm"
    echo "Path to the php.ini directory: /opt/php-${php72}/lib"
    echo "Path to the PHP-FPM pool directory: /opt/php-${php72}/etc/php-fpm.d"
fi

if [[ "$php56" != "" ]]; then

    read -p "Press Enter to continue to PHP ${php56}"

    echo "========================================================="
    echo "Installing PHP ${php56} to /opt/${php56}"

    mkdir -p /opt/php-${php56}
    mkdir /usr/local/src/php${php56}-build
    cd /usr/local/src/php${php56}-build
    wget http://de2.php.net/get/php-${php56}.tar.bz2/from/this/mirror -O php-${php56}.tar.bz2
    tar jxf php-${php56}.tar.bz2
    cd /tmp
    wget "https://www.openssl.org/source/old/1.0.1/openssl-1.0.1t.tar.gz"
    tar xzf openssl-1.0.1t.tar.gz 
    cd openssl-1.0.1t
    ./config shared --prefix=/opt/openssl
    make -j $(nproc) && make install
    ln -s /opt/openssl/lib /opt/openssl/lib/x86_64-linux-gnu
    wget -O /opt/openssl/ssl/cert.pem "http://curl.haxx.se/ca/cacert.pem"
    mkdir /usr/include/freetype2/freetype
    ln -s /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h
    ln -s /opt/openssl/lib/libcrypto.so.1.0.0 /usr/lib/x86_64-linux-gnu/
    ln -s /opt/openssl/lib/libssl.so.1.0.0 /usr/lib/x86_64-linux-gnu/
    ln -fs /opt/openssl /usr/local/ssl
    cd /usr/local/src/php${php56}-build/php-${php56}/
    ./configure --prefix=/opt/php-${php56} --with-pdo-pgsql --with-zlib-dir --with-freetype-dir \
    --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl \
    --with-mcrypt --with-zlib --with-pgsql --disable-rpath --enable-inline-optimization \
    --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl \
    --enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip \
    --with-pcre-regex --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock \
    --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf --with-openssl=/opt/openssl \
    --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu --enable-ftp \
    --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-fpm
    make
    make install

    cp /usr/local/src/php${php56}-build/php-${php56}/php.ini-production /opt/php-${php56}/lib/php.ini
    cp /opt/php-${php56}/etc/php-fpm.conf.default /opt/php-${php56}/etc/php-fpm.conf

    echo "Please update /opt/php-${php72}/etc/php-fpm.conf"
    echo "Edit the following:"
    cat << EOF
[...]
pid = run/php-fpm.pid
[...]
user = www-data
group = www-data
[...]
listen = 127.0.0.1:8997
[...]
include=/opt/php-${php56}/etc/php-fpm.d/*.conf
EOF

    read -p "Press Enter to continue"

    vi /opt/php-${php56}/etc/php-fpm.conf

    cat >> /lib/systemd/system/php-${php56}-fpm.service <<EOF
[Unit]
Description=The PHP ${php56} FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=/opt/php-${php56}/var/run/php-fpm.pid
ExecStart=/opt/php-${php56}/sbin/php-fpm --nodaemonize --fpm-config /opt/php-${php56}/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

    echo "Please check the service file: /lib/systemd/system/php-${php56}-fpm.service"
    read -p "Press Enter to continue"
    vi /lib/systemd/system/php-${php56}-fpm.service

    systemctl enable php-${php56}-fpm.service
    systemctl daemon-reload
    systemctl start php-${php56}-fpm.service

    echo "Enabling Zend OPcache"
    echo "zend_extension=opcache.so" >> /opt/php-${php56}/lib/php.ini


    echo "Building Memcache"
    apt-get install libmemcached-dev
    cd /opt/php-${php56}/etc
    pecl -C ./pear.conf update-channels
    pecl -C ./pear.conf install memcache

    echo "Enabling Memcached"
    echo "extension=memcache.so" >> /opt/php-${php56}/lib/php.ini

    echo "Starting PHP ${php56} FPM service"
    systemctl start php-${php56}-fpm.service

    echo "Checking PHP Version"
    cd /opt/php-${php56}/bin
    ./php --version

    read -p "Press Enter to continue"

    echo "ISPConfig Settings"
    echo "-> Name Tab"
    echo "PHP Name: PHP ${php56}"
    echo "-> FastCGI Settings Tab"
    echo "Path to the PHP FastCGI binary: /opt/php-${php56}/bin/php-cgi"
    echo "Path to the php.ini directory: /opt/php-${php56}/lib"
    echo "-> PHP-FPM Settings tab"
    echo "Path to the PHP-FPM init script: php-${php56}-fpm"
    echo "Path to the php.ini directory: /opt/php-${php56}/lib"
    echo "Path to the PHP-FPM pool directory: /opt/php-${php56}/etc/php-fpm.d"
fi
read -p "Press Enter to finish"

