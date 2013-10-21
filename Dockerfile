FROM ubuntu:latest 

MAINTAINER Andrew Oke "andrew.oke@gmail.com" 

ENV MYSQLTMPROOT xkThETQNM7D6Yf 

RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise universe" >> /etc/apt/sources.list
RUN apt-get update

RUN apt-get -y install dialog net-tools lynx nano wget software-properties-common vim python-software-properties
RUN add-apt-repository -y ppa:nginx/stable
RUN add-apt-repository -y ppa:ondrej/php5
RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
RUN add-apt-repository 'deb http://mirror.weathercity.com/mariadb/repo/10.0/ubuntu precise main'
RUN add-apt-repository 'deb http://security.ubuntu.com/ubuntu precise-security main '
RUN apt-get update

RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

RUN apt-get install -y git lynx drush
RUN echo "mysql-server mysql-server/root_password password $MYSQLTMPROOT" | debconf-set-selections && echo "mysql-server mysql-server/root_password_again password $MYSQLTMPROOT" | debconf-set-selections && apt-get install -y mariadb-server
RUN apt-get -y install nginx php5-fpm php5-mysql php5-imagick php5-imap php5-mcrypt php5-curl php5-memcached php5-cli php5-dev php5-json php5-gd  mysqltuner varnish libmemcached6 memcached && apt-get -y install nginx-extras

#mysql config
RUN cat /proc/mounts > /etc/mtab && sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/my.cnf
RUN (start-stop-daemon --start -b --exec /usr/sbin/mysqld && sleep 5 ; echo "create database main character set utf8;" | mysql -u root -p$MYSQLTMPROOT )

#varnish
RUN wget https://gist.github.com/andrewoke/7075074/raw/798fb6d75afb02c65b3cb1c5d819474635a18def/default.vcl -O /etc/varnish/default.vcl
RUN sed -i 's/\-a\ \:6081/\-a \:80/g' /etc/default/varnish

#memcached
RUN pecl install memcache

EXPOSE 80

RUN wget https://gist.github.com/andrewoke/7077877/raw/7dc7923d7fa4fbb6c7b62d8ab91365a2eb0c555e/start.sh -O /start.sh
RUN chmod +x /start.sh

CMD /start.sh 
