# Install Docker on Ubuntu 18.04 LTS

Install Docker on Ubuntu 16.04 LTS. Below is a bash script containing a number of commands which will automatically install Docker on your VPS or dedicated server.


```bash
#!/bin/bash

apt-get update
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
apt-get update
#apt-cache policy docker-engine

#apt-get update
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
#apt-get update
apt-get install -y docker-engine
service docker start
```

Now Docker is installed on your Ubuntu box... Time to install WordPress
