#!/bin/sh
if [ -d /data ]; then
  # make nginx cache dir
  if [ ! -d /var/cache/nginx ]; then
    mkdir /var/cache/nginx
  fi
  # make data/conf directory if it doesn't exist
  if [ ! -d /data/conf ]; then
    mkdir /data/conf
  fi
  # mv mysql directory to data if it doesn't exist. chown it if it does just to be safe
  if [ ! -d /data/mysql ]; then
    mv /var/lib/mysql /data/mysql
    chown -R mysql:mysql /data/mysql
  else
    chown -R mysql:mysql /data/mysql
  fi
  # if /data/www doesn't exist create it. If it does and /var/www isn't linked link and chown it
  if [ ! -d /data/www ]; then
    mkdir /var/www
    echo "<?php phpinfo(); ?>" > /var/www/index.php
    mv /var/www /data/www
    ln -s /data/www /var/www
    chown -R www-data:www-data /data/www
  elif [ ! -L /var/www ] && [ -d /data/www ]; then
    rm -rf /var/www
    ln -s /data/www /var/www
    chown -R www-data:www-data /data/www
  fi  
  # move mysql conf to /data/conf/mysql. link it if not linked 
  if [ ! -d /data/conf/mysql ]; then
    sed -i 's/\/var\/lib\/mysql/\/data\/mysql/g' /etc/mysql/my.cnf
    mv /etc/mysql /data/conf/mysql
    ln -s /data/conf/mysql /etc/mysql
  elif [ ! -L /etc/mysql ] && [ -d /data/conf/mysql ]; then
    rm -rf /etc/mysql
    ln -s /data/conf/mysql /etc/mysql
  fi
  # move php conf to /data/conf/php. link it if link doesn't exist
  if [ ! -d /data/conf/php5 ]; then
    mv /etc/php5 /data/conf/php5
    ln -s /data/conf/php5 /etc/php5
    echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
    sed -i 's/\/var\/run\/php5-fpm.sock/\/var\/run\/php-fpm.sock/g' /etc/php5/fpm/pool.d/www.conf
  elif [ ! -L /etc/php5 ] && [ -d /data/conf/php5 ]; then
    rm -rf /etc/php5
    ln -s /data/conf/php5 /etc/php5
  fi
  # move nginx conf to /data/conf/nginx, make sure /etc/nginx links to it
  if [ ! -d /data/conf/nginx ]; then
    mv /etc/nginx /etc/nginx.orig
    rm -rf /etc/nginx
    git clone https://github.com/perusio/drupal-with-nginx.git /data/conf/nginx
    ln -s /data/conf/nginx /etc/nginx
    rm -rf /data/conf/nginx/sites-available/000-default
    rm -rf /data/conf/nginx/sites-available/example.com.conf
    mv /default /data/conf/nginx/sites-available/default
    mkdir /var/cache/nginx
    mkdir /data/conf/nginx/sites-enabled
    ln -s /data/conf/nginx/sites-available/default /data/conf/nginx/sites-enabled/default
    sed -i 's/aio\ on/\#aio\ on/g' /data/conf/nginx/apps/drupal/drupal.conf
    sed -i 's/\#include\ upstream_phpcgi_unix\.conf/include\ upstream_phpcgi_unix\.conf/g' /data/conf/nginx/nginx.conf
    sed -i 's/include\ upstream_phpcgi_tcp\.conf/\#include\ upstream_phpcgi_tcp.conf/g' /data/conf/nginx/nginx.conf
    sed -i 's/default_type\ application\/octet\-stream\;/default_type\ application\/octet\-stream\;\nvariables_hash_max_size\ 1024\;/g' /data/conf/nginx/nginx.conf    
    echo "daemon off;" >> /data/conf/nginx/nginx.conf
  elif [ ! -L /etc/nginx ] && [ -d /data/conf/nginx ]; then
    rm -rf /etc/nginx
    ln -s /data/conf/nginx /etc/nginx
  fi
  # move varnish config to /data/conf/varnish. link if not a link
  if [ ! -d /data/conf/varnish ]; then 
    mv /etc/varnish /data/conf/varnish
    ln -s /data/conf/varnish /etc/varnish
  elif [ ! -L /etc/varnish ] && [ -d /data/conf/varnish ]; then
    rm -rf /etc/varnish
    ln -s /data/conf/varnish /etc/varnish
  fi
  # move memcached to /data/conf, link if not a link
  if [ ! -f /data/conf/memcache.conf ]; then
    mv /etc/memcached.conf /data/conf/memcached.conf
    ln -s /data/conf/memcached.conf /etc/memcached.conf
  elif [ ! -L /etc/memcached.conf ] && [ -f /data/conf/memcached.conf ]; then
    rm -rf /etc/memcached.conf
    ln -s /data/conf/memcached.conf /etc/memcached.conf
  fi
fi
 
service memcached start
service mysql start
service varnish start
php5-fpm -R && nginx &
/bin/bash
