# Quick start, manual provisioning
## Our custom docker image
First install Docker... see above for a link. We are using Docker 1.9.1. We are running Ubuntu 14.04.2 LTS

The following is a quick tutorial for deploying your site on Docker. It has been tested and works with sites like www.etopian.com. It also supports using an SSL certificate. It uses Alpine Linux for serving the actual site, the beautiful thing is that a site can be served in around 50mb of ram. Using the process below you can deploy multiple WP sites on the same box, at least 10 sites on a 1gb VPS extremely securely as each site lives in its own container.

We are in the process of developing a CLI to make this process much easier, star this repo:
https://github.com/etopian/docker-wordpress-cli

For this demo we are deploying etopian.com, replace that with your custom domain.

###Security
The process serving the website, Nginx and PHP-FPM, does not run as root. It's no less secure than running a non-root user like www-data to serve your site. If you can breakout to root within the container, you can potentially get to the host system. But that's absolutely no different than any other Linux system. If you break out of www-data on a normal setup to root, then you have root.

###IP address fix
Once you finish this you will find that logs command does not show the correct IP address. In order to fix this you must do the following:

edit /etc/default/docker

```bash
DOCKER_OPTS="--userland-proxy=false --storage-driver=aufs"
```


###Site files

Site files need to be located in, simply copy the files here:

```
#copy your WP install here, if you don't have one simply download WP and put that here
/data/sites/etopian.com/htdocs
```


### File ownership
The site on your host needs proper file permissions. Go to your site's folder and type the following:

```
chown -R 100:101 htdocs/
```

###NGinx Proxy
This sits in front of all of your sites at port 80 serving all your sites.

```
docker run -d --name nginx -p 80:80 -p 443:443 -v /etc/nginx/htpasswd:/etc/nginx/htpasswd -v /etc/nginx/vhost.d:/etc/nginx/vhost.d:ro -v /etc/nginx/certs:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock:ro etopian/nginx-proxy
```

###PHP-FPM + Nginx
Each site runs in its own container with PHP-FPM and Nginx instance.
```
docker run -d --name etopian_com -e VIRTUAL_HOST=www.etopian.com,etopian.com -v /data/sites/etopian.com:/DATA etopian/alpine-php-wordpress
```

##MySQL Database

```
apt-get update && apt-get install mysql-client-core-5.6

docker run -d --name mariadb -p 172.17.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=myROOTPASSOWRD -v /data/mysql:/var/lib/mysql mariadb

#login to mariadb
mysql -uroot -pmyROOTPASSOWRD -h 172.17.0.1 -P 3306

#create the db in mariadb
CREATE DATABASE etopian_com;
CREATE USER 'etopian_com'@'%' IDENTIFIED BY 'mydbpass';
GRANT ALL PRIVILEGES ON  etopian_com.* TO 'etopian_com'@'%';

#if you have a db, import it. if not then configure wp and install it using the interface.
mysql -uroot -pmyROOTPASSOWRD -h 172.17.0.1 etopian_com < mydatabase.mysql
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

Mailgun works fine but the test on the WP mailgun plugin to see if it is working does not because it does not correctly set the e-mail address before attempting to send an e-mail

* [https://wordpress.org/plugins/mailgun/](https://wordpress.org/plugins/mailgun/) (recommended)
* https://wordpress.org/plugins/wp-ses/
* https://wordpress.org/plugins/wp-smtp/
* https://wordpress.org/plugins/easy-wp-smtp/
* https://wordpress.org/plugins/wp-mail-bank/

##How can I see the logs?
Currently, working on improving this:
```
docker logs nginx
```

##WP-CLI

WP-CLI is included in the Alpine Linux image. You need the following option when running the Alpine Linux container to not see the error when trying to use it.

```
-e TERM=xterm
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

### Adding new PHP modules to a certain site
The image for Alpine Linux running PHP may be found here:
https://github.com/etopian/alpine-php-wordpress

The following modules are included with the image etopian/alpine-php-wordpress
```
    php-fpm php-json php-zlib php-xml php-pdo php-phar php-openssl \
    php-pdo_mysql php-mysqli \
    php-gd php-iconv php-mcrypt \
    php-mysql php-curl php-opcache php-ctype php-apcu \
    php-intl php-bcmath
```
### Kernel Upgrade

The kernel upgrade to 3.19 on Ubuntu 14.04 is not recommend/possible. It will cause your Docker instance to fail. The reason is that 3.19 kernel does not have AUFS. Docker is switching to another file provider, but for now stick with the 3.13 kernel. Downgrade to 3.13 if you have upgraded and Docker won't start.

### Log Rotate



### PHP Modules
#### List of available modules in Alpine Linux, not all these are installed.
##### In order to install a php module do, (leave out the version number i.e. -5.6.11-r0
```
docker exec <image_id> apk add <pkg_name>
docker restart <image_name>
```
Example:

```
docker exec <image_id> apk update #do this once.
docker exec <image_id> apk add php-soap
docker restart <image_name>
```


php-soap-5.6.11-r0

php-openssl-5.6.11-r0

php-gmp-5.6.11-r0

php-phar-5.6.11-r0

php-embed-5.6.11-r0

php-pdo_odbc-5.6.11-r0

php-mysqli-5.6.11-r0

php-common-5.6.11-r0

php-ctype-5.6.11-r0

php-fpm-5.6.11-r0

php-shmop-5.6.11-r0

php-xsl-5.6.11-r0

php-curl-5.6.11-r0

php-pear-net_idna2-0.1.1-r0

php-json-5.6.11-r0

php-dom-5.6.11-r0

php-pspell-5.6.11-r0

php-sockets-5.6.11-r0

php-pear-mdb2-driver-pgsql-2.5.0b5-r0

php-pdo-5.6.11-r0

phpldapadmin-1.2.3-r3

php-pear-5.6.11-r0

php-phpmailer-5.2.0-r0

phpmyadmin-doc-4.4.10-r0

php-cli-5.6.11-r0

php-zip-5.6.11-r0

php-pgsql-5.6.11-r0

php-sysvshm-5.6.11-r0

php-imap-5.6.11-r0

php-intl-5.6.11-r0

php-embed-5.6.11-r0

php-zlib-5.6.11-r0

php-phpdbg-5.6.11-r0

php-sysvsem-5.6.11-r0

phpmyadmin-4.4.10-r0

php-mysql-5.6.11-r0

php-sqlite3-5.6.11-r0

php-cgi-5.6.11-r0

php-apcu-4.0.7-r1

php-snmp-5.6.11-r0

php-pdo_pgsql-5.6.11-r0

php-xml-5.6.11-r0

php-wddx-5.6.11-r0

php-sysvmsg-5.6.11-r0

php-enchant-5.6.11-r0

php-bcmath-5.6.11-r0

php-pear-mail_mime-1.8.9-r0

php-apache2-5.6.11-r0

php-gd-5.6.11-r0

php-pear-mdb2-driver-sqlite-2.5.0b5-r0

php-xcache-3.2.0-r1

php-odbc-5.6.11-r0

php-mailparse-2.1.6-r2

php-ftp-5.6.11-r0

perl-php-serialization-0.34-r1

php-exif-5.6.11-r0

php-pdo_mysql-5.6.11-r0

php-ldap-5.6.11-r0

php-pear-mdb2-2.5.0b5-r0

php-dbg-5.6.11-r0

php-pear-net_smtp-1.6.2-r0

php-opcache-5.6.11-r0

php-pdo_sqlite-5.6.11-r0

php-posix-5.6.11-r0

php-dba-5.6.11-r0

php-iconv-5.6.11-r0

php-gettext-5.6.11-r0

php-xmlreader-5.6.11-r0

php-5.6.11-r0

php-xmlrpc-5.6.11-r0

php-bz2-5.6.11-r0

perl-php-serialization-doc-0.34-r1

php-mcrypt-5.6.11-r0

php-memcache-3.0.8-r3

xapian-bindings-php-1.2.21-r1

php-pdo_dblib-5.6.11-r0

php-phalcon-2.0.3-r0

php-dev-5.6.11-r0

php-doc-5.6.11-r0

php-mssql-5.6.11-r0

php-calendar-5.6.11-r0

php-pear-mdb2-driver-mysqli-2.5.0b5-r0

php-pear-mdb2-driver-mysql-2.5.0b5-r0




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
Docker DOES NOT own, operate, license, sponsors or authorizes this site. Docker® is a registered trademark of Docker, Inc. dockerwordpress.com WordPress Tutorial is not affiliated with Docker, Inc.