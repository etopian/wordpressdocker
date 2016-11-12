# Deploying Docker on WordPress

## Introduction

Docker is a great technology which can be used for many purposes. One purpose for using Docker is to deploy WordPress. This tutorial covers deploying **multiple WordPress websites** on Docker. For this demo we are deploying etopian.com, replace that with your custom domain.

## Our custom docker image
The following is a quick tutorial for deploying your site on Docker. It has been tested and works with sites like www.etopian.com. It also supports using an SSL certificate. It uses Alpine Linux for serving the actual site, the beautiful thing is that a site can be served in around 50mb of ram. Using the process below you can deploy multiple WP sites on the same box, at least 10 sites on a 1gb VPS extremely securely as each site lives in its own container. This container uses Alpine Linux Edge with PHP7. We have found this to be a stable solution, despite being Edge being the testing branch of Alpine Linux.

###Security
The process serving the website, Nginx and PHP-FPM, does not run as root. It's no less secure than running a non-root user like www-data to serve your site. If you can breakout to root within the container, you can potentially get to the host system. But that's absolutely no different than any other Linux system. If you break out of www-data on a normal setup to root, then you have root. See [Why use Docker with WordPress](docker/Why-use-Docker-with-WordPress) for more.

## Design decisions
We do not use Docker's volume feature. Instead all files including the MariaDB data directory are mounted directory from the host. All your files are on the host in the /data directory on your host. This helps with backups and in generally is a safe way of dealing with files while dealing with Docker. Docker's volumes feature leaves much to be desired so it is not used. All the NGINX config directories are mounted to /etc/nginx on the host for easy editing and management.

Each WordPress Container runs:

* Nginx
* PHP-FPM

Currently there is no process manager running in the WordPress container. We have it on our todo list to use s6 as the process manager. The nginx user is enabled on each container so you can bash into the container as the same user as the site, to use wp-cli. This is a minor security risk. Currrently there is no way to directly SSH into the container, you have to go through the host. There are no plans to add SSH to the container, you have to that yourself if that's something you need.

## Install Docker

First [install Docker](docker/Install-Docker-on-Ubuntu/). We are using Docker 1.12.3. We are running Ubuntu Xenial 16.04 LTS

##Prepare your WordPress site

Site files need to be located in /data/sites/etopian.com/htdocs, simply copy the files here:

```
mkdir -p /data/sites/etopian.com/htdocs
#Copy your WP install here, if you don't have one simply download WP and put that here
/data/sites/etopian.com/htdocs
```

### File ownership
The site on your host needs proper file permissions. Go to your site's folder and type the following:

```
chown -R 100:101 htdocs/
```

## Run NGINX Reverse Proxy Container
This sits in front of all of your sites at port 80 and 443 serving all your sites. It was automatically reconfigure itself and reload itself when you create a new WordPress site container.

```
docker run -d --name nginx -p 80:80 -p 443:443 -v /etc/nginx/htpasswd:/etc/nginx/htpasswd -v /etc/nginx/vhost.d:/etc/nginx/vhost.d:ro -v /etc/nginx/certs:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock:ro etopian/nginx-proxy
```

## Run WordPress Container
Each site runs in its own container with PHP-FPM and Nginx instance.
```
docker run -d --name etopian_com -e VIRTUAL_HOST=www.etopian.com,etopian.com -v /data/sites/etopian.com:/DATA etopian/alpine-php-wordpress
```

##Run MySQL/MariaDB Database Container

In order to access MySQL/MariaDB running in a container you need a MySQL client on your host. You can alternatively using the client in the container, described below.

### Install MariaDB
```
docker run -d --name mariadb -p 172.17.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=myROOTPASSOWRD -v /data/mysql:/var/lib/mysql mariadb
```

### Use MySQL from the host

```bash
apt-get update && apt-get install mariadb-client-10.0

#login to mariadb
mysql -uroot -pmyROOTPASSOWRD -h 172.17.0.1 -P 3306

#create the db in mariadb
CREATE DATABASE etopian_com;
CREATE USER 'etopian_com'@'%' IDENTIFIED BY 'mydbpass';
GRANT ALL PRIVILEGES ON  etopian_com.* TO 'etopian_com'@'%';

#if you have a db, import it. if not then configure wp and install it using the interface.
mysql -uroot -pmyROOTPASSOWRD -h 172.17.0.1 etopian_com < mydatabase.mysql
```

### Use MySQL client in the container image

```bash
docker cp mydatabase.sql mariadb:/tmp/mydatabase.mysql
docker exec -it mariadb bash
export TERM=xterm
cd /tmp
mysql -uroot -pmyROOTPASSOWRD < mydatabase.mysql

```

## Configure WP


###wp-config.php
If you need to change the domain of the site put the follow in wp-config.php of your site.

```php
/** The name of the database for WordPress **/
define('DB_NAME', 'etopian_com");

/** MySQL database username **/
define('DB_USER', 'etopian_com');

/** MySQL database password **/
define('DB_PASSWORD', 'mydbpass');

/** MySQL hostname **/
define('DB_HOST', '172.17.0.1');
```

Your site should be working as long as the DNS entries are properly set.


### wp-config.php - SSL
Put your SSL certificate here, with the VIRTUAL_HOST as the file name: 
```
/etc/nginx/certs
etopian.com.crt  etopian.com.csr  etopian.com.key
```

If you use SSL you need to run your container with the filename of the certificate you are using. So rm the existing container and recreate a new one with the following environmental variable.
```
 -e CERT_NAME=etopian.com
```

edit wp-config.php in your site's htdocs directory.

```
define('WP_HOME','https://etopian.com');
define('WP_SITEURL','https://etopian.com');
  define('FORCE_SSL_ADMIN', true);
if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')
       $_SERVER['HTTPS']='on';
```

###wp-config.php
If you need to change the domain of the site put the follow in wp-config.php of your site.

```
define('WP_HOME','http://etopian.com');
define('WP_SITEURL','http://etopian.com');
```


##Mail
Mail is not routed by the container, you must use an SMTP plugin or Mailgun or AWS SES to route your site's email.

Mailgun WP Plugin works fine in the container but the test to see if it is working will fail because it does not correctly set the e-mail address before attempting to send an e-mail. Simply ignore the error, and test the mail from your actual site to make sure it's working.

* [https://wordpress.org/plugins/mailgun/](https://wordpress.org/plugins/mailgun/) (recommended)
* https://wordpress.org/plugins/wp-ses/
* https://wordpress.org/plugins/wp-smtp/
* https://wordpress.org/plugins/easy-wp-smtp/
* https://wordpress.org/plugins/wp-mail-bank/

##Logs
You can view the logs of all you sites using the NGINX proxy container.

```
docker logs nginx
```

If you want to view logs for an individual site, they are in the logs directory on your host.

```
cd /data/sites/etopian.com/logs
cat access.log
```

##WP-CLI

WP-CLI is included in the Alpine Linux image. To use it from inside the container in a safe way.

```
docker exec -it <container_name> bash
su nginx
cd /DATA
wp-cli
```

## Redis
It is possible to speed up your site with Redis... You need enough memory to support Redis obviously.

You need the following WP plugin:
https://wordpress.org/plugins/redis-cache/

Put this in your wp-config.php below the DB_HOST and DB_NAME entries.
```
define('WP_REDIS_HOST', DB_HOST);
define('WP_CACHE_KEY_SALT', DB_NAME); 
```

Deploy Redis
```
docker run --name redis -p 172.17.0.1:6379:6379 redis
```

Go to your site's dashboard and activate the Redis object cache.

Settings > Redis and click the button to activate.

![wp_redis.png](http://assets.dockerwordpress.com.s3.amazonaws.com/images/wp_redis.png)


## Modifying the image

The image for Alpine Linux running PHP may be found here:
https://github.com/etopian/alpine-php-wordpress

You may fork it and modify it to add additional modules and what not.

## Adding new PHP modules

> The following modules are included with the image etopian/alpine-php-wordpress

```
    php7-fpm php7-json php7-zlib php7-xml php7-pdo php7-phar php7-openssl \
    php7-pdo_mysql php7-mysqli php7-session \
    php7-gd php7-iconv php7-mcrypt \
    php7-curl php7-opcache php7-ctype php7-apcu \
    php7-intl php7-bcmath php7-dom php7-xmlreader
```


## List of PHP Modules

> List of available modules in Alpine Linux, not all these are installed.

> In order to install a php module do, (leave out the version number i.e. -5.7.0.13-r0


```
docker exec <container_name> apk add <pkg_name>
docker restart <container_name>

```

Example:

```
docker exec <container_name> apk update #do this once.
docker exec <container_name> apk add php-soap
docker restart <container_name>
```


```
php7-intl-7.0.13-r0
php7-openssl-7.0.13-r0
php7-dba-7.0.13-r0
php7-sqlite3-7.0.13-r0
php7-pear-7.0.13-r0
php7-phpdbg-7.0.13-r0
php7-litespeed-7.0.13-r0
php7-gmp-7.0.13-r0
php7-pdo_mysql-7.0.13-r0
php7-pcntl-7.0.13-r0
php7-common-7.0.13-r0
php7-oauth-2.0.1-r0
php7-xsl-7.0.13-r0
php7-fpm-7.0.13-r0
php7-gmagick-2.0.4_rc1-r2
php7-mysqlnd-7.0.13-r0
php7-enchant-7.0.13-r0
php7-solr-2.4.0-r0
php7-uuid-1.0.4-r0
php7-pspell-7.0.13-r0
php7-ast-0.1.1-r0
php7-redis-3.0.0-r1
php7-snmp-7.0.13-r0
php7-doc-7.0.13-r0
php7-mbstring-7.0.13-r0
php7-lzf-1.6.5-r1
php7-timezonedb-2016.3-r0
php7-dev-7.0.13-r0
php7-xmlrpc-7.0.13-r0
php7-rdkafka-2.0.0-r0
php7-stats-2.0.1-r0
php7-embed-7.0.13-r0
php7-xmlreader-7.0.13-r0
php7-pdo_sqlite-7.0.13-r0
php7-exif-7.0.13-r0
php7-msgpack-2.0.1-r0
php7-opcache-7.0.13-r0
php7-ldap-7.0.13-r0
php7-posix-7.0.13-r0
php7-session-7.0.13-r0
php7-gd-7.0.13-r0
php7-gettext-7.0.13-r0
php7-mailparse-3.0.1-r0
php7-json-7.0.13-r0
php7-xml-7.0.13-r0
php7-mongodb-1.1.4-r1
php7-7.0.13-r0
php7-iconv-7.0.13-r0
php7-sysvshm-7.0.13-r0
php7-curl-7.0.13-r0
php7-shmop-7.0.13-r0
php7-odbc-7.0.13-r0
php7-phar-7.0.13-r0
php7-pdo_pgsql-7.0.13-r0
php7-imap-7.0.13-r0
php7-pdo_dblib-7.0.13-r0
php7-pgsql-7.0.13-r0
php7-pdo_odbc-7.0.13-r0
php7-xdebug-2.4.1-r0
php7-zip-7.0.13-r0
php7-apache2-7.0.13-r0
php7-cgi-7.0.13-r0
php7-ctype-7.0.13-r0
php7-inotify-2.0.0-r0
php7-couchbase-2.2.3-r1
php7-amqp-1.7.1-r0
php7-mcrypt-7.0.13-r0
php7-readline-7.0.13-r0
php7-wddx-7.0.13-r0
php7-cassandra-1.2.2-r0
php7-libsodium-1.0.6-r0
php7-bcmath-7.0.13-r0
php7-calendar-7.0.13-r0
php7-tidy-7.0.13-r0
php7-dom-7.0.13-r0
php7-sockets-7.0.13-r0
php7-zmq-1.1.3-r0
php7-memcached-3.0_pre20160808-r0
php7-soap-7.0.13-r0
php7-apcu-5.1.6-r0
php7-sysvmsg-7.0.13-r0
php7-zlib-7.0.13-r0
php7-ssh2-1.0-r0
php7-ftp-7.0.13-r0
php7-sysvsem-7.0.13-r0
php7-pdo-7.0.13-r0
php7-bz2-7.0.13-r0
php7-mysqli-7.0.13-r0
```



## Firewall

You should also deploy a firewall on your box. However, it's very easy to lock yourself out of your box, so I will not give you exact instructions on how to do it. The following is what I use for my box using arno-iptables-firewall.

Once the firewall is in place, notice when the box reboots, Docker might not start in the right order and therefore the iptables rules it might need might not be initialized and due to this things might not work. Simply restart the Docker service:

```
service docker restart
```


```
#######################################################################
# Feel free to edit this file.  However, be aware that debconf writes #
# to (and reads from) this file too.  In case of doubt, only use      #
# 'dpkg-reconfigure -plow arno-iptables-firewall' to edit this file.  #
# If you really don't want to use debconf, or if you have specific    #
# needs, you're likely better off using placing an additional         #
# configuration snippet into/etc/arno-iptables-firewall/conf.d/.      #
# Also see README.Debian.                                             #
#######################################################################


EXT_IF="eth0"
EXT_IF_DHCP_IP=1
OPEN_TCP="22 80 443"
OPEN_UDP=""
INT_IF="docker0"
NAT=1
INTERNAL_NET="172.17.0.1/16"
NAT_INTERNAL_NET="192.168.1.0/24 192.168.2.0/24 172.17.0.1/16"
OPEN_ICMP=1
```


### Have issues, comments or questions: https://github.com/etopian/docker-wordpress/issues

---
Docker DOES NOT own, operate, license, sponsors or authorizes this site. Docker® is a registered trademark of Docker, Inc. wordpressdocker.com Unofficial WordPress Docker Tutorial is not affiliated with Docker, Inc.