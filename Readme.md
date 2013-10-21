Dockerfile which will install:

LEMP
Memcache
Varnish
PHP5-FPM
Perusio Drupal nginx config

Concepts:
The idea behind this container is to have an automated way to launch a D7 high performance environment. Once the container is finished building you can launch a new container. The idea is that you should mount a folder into the container at /data. If you launch the container with the start command /start.sh it will move all the config files to /data/conf, move mysql to /data/mysql and then create /data/www which /var/www links to. This allows you to have a highly portable container which will allow you to easily performance tune drupal, persistent mysql store, and persistent web files.
