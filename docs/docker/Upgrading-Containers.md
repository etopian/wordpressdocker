# Upgrading Containers

One of the key benefits of using Docker is the fact that it makes deployment of software eaiser. It packs everything you need into an container and ships that entire container with the entire enviornment. This makes deploying more predictable than the old method of just pushing the files and then keeping the operating system up to date in hopes that everything keeps working.


## The Old Way
Site upgrades currently are difficult. If, for instance, you are using Ubuntu you can upgrade a website quickly using something like the following:

```code
apt-get update && apt-get upgrade
```

If you do this, what guarantees do you have that your site will actually come up after the upgrade is done? None! An upgrade may very well kill your site and there is no way to revert the site if this happens.

With Docker things are different. If you need to upgrade your site, you do not upgrade the entire operating system. You deploy a new container running a single site, your site, while keeping the existing container so you can revert if the upgrade fails. 

# The Docker Way

Say that you deploy a new WP site with Docker (a contrived example):
```code
docker run -d --name=mysite_com -v /data/mysite_com:/var/sites/mysite_com wordpress
```

A few months later a new container is released for WordPress. This new container includes a new version of PHP.

```code
docker pull wordpress
```

Now you can rename your existing container:

```code
docker rename mysite_com mysite_com_old
```

Stop the old container:

```code
docker stop mysite_com_old
```

Start a new container, with the new image that you pulled:
```code
docker run -d --name=mysite_com -v /data/mysite_com:/var/sites/mysite_com wordpress
```

If the new container is not working, stop the new site:
```code
docker stop mysite_com
```

Rename it to _notworking:
```code
docker rename mysite_com mysite_com_notworking
```

Rename the old container back:
```code
docker rename mysite_com_old mysite_com
```

Restart the old container:
```code
docker start mysite_com
```

Remove the nonworking container:
```code
docker rm mysite_com_notworking
```