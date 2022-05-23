#!/bin/bash
sudo su
yum update -y
yum install docker git -y
systemctl start docker
chmod 666 /var/run/docker.sock

git clone git@github.com:bmukum/quest.git
cd quest
docker build -t rearc .
docker run -d rearc