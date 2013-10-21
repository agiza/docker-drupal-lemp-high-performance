FROM ubuntu:latest 

MAINTAINER Andrew Oke "andrew.oke@gmail.com" 

ENV MYSQLTMPROOT xkThETQNM7D6Yf 

RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise universe" >> /etc/apt/sources.list
RUN apt-get update

RUN apt-get -y install dialog net-tools lynx nano wget software-properties-common vim
RUN apt-get -y install python-software-properties
RUN add-apt-repository -y ppa:nginx/stable
RUN add-apt-repository -y ppa:ondrej/php5
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
RUN add-apt-repository 'deb http://mirror.weathercity.com/mariadb/repo/10.0/ubuntu precise main'
RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu precise-security main '
RUN apt-get update

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

RUN apt-get install -y git lynx drush
RUN echo "mysql-server mysql-server/root_password password $MYSQLTMPROOT" | debconf-set-selections && echo "mysql-server mysql-server/root_password_again password $MYSQLTMPROOT" | debconf-set-selections && apt-get install -y mariadb-server
RUN apt-get -y install nginx php5-fpm php5-mysql php5-imagick php5-imap php5-mcrypt php5-curl php5-memcached php5-cli php5-dev php5-json php5-gd
RUN apt-get -y install mysqltuner
RUN apt-get -y install varnish libmemcached6 memcached 

#nginx config
RUN mv /etc/nginx /etc/nginx.orig
RUN git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
#RUN git checkout D7
RUN rm -rf /etc/nginx/sites-available 
RUN mkdir /etc/nginx/sites-available
RUN wget https://gist.github.com/andrewoke/7077555/raw/40c81e39207b8935e704fcdd10c50bfe032a779c/perusio-docker-default.conf -O /etc/nginx/sites-available/default
RUN mkdir /var/cache/nginx
RUN mkdir /etc/nginx/sites-enabled
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
RUN sed -i 's/aio\ on/\#aio\ on/g' /etc/nginx/apps/drupal/drupal.conf
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir /var/www
RUN echo "<?php phpinfo(); ?>" > /var/www/index.php

#mysql config
RUN cat /proc/mounts > /etc/mtab
RUN sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/my.cnf
RUN (start-stop-daemon --start -b --exec /usr/sbin/mysqld && sleep 5 ; echo "create database main character set utf8;" | mysql -u root -p$MYSQLTMPROOT )

#varnish
RUN wget https://gist.github.com/andrewoke/7075074/raw/798fb6d75afb02c65b3cb1c5d819474635a18def/default.vcl -O /etc/varnish/default.vcl
RUN sed -i 's/\-a\ \:6081/\-a \:80/g' /etc/default/varnish

#memcached
RUN pecl install memcache

#php5-fpm
RUN sed -i 's/\/var\/run\/php5-fpm.sock/\/var\/run\/php-fpm.sock/g' /etc/php5/fpm/pool.d/www.conf


EXPOSE 80

VOLUME ["/data"]

RUN wget https://gist.github.com/andrewoke/7077877/raw/fa2907463def1df2c27f33c8c4394de85caf553f/start.sh -O /start.sh
RUN chmod +x /start.sh

CMD /start.sh 
