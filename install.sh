#!/bin/bash

apt update && \
apt dist-upgrade -y && \
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" && \
apt update && \
apt install -y \
	docker-ce \
	docker-compose
