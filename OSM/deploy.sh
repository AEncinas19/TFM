#!/bin/bash

microk8s enable registry

sudo touch /etc/docker/daemon.json
echo '{"insecure-registries": ["192.168.56.11:32000"]}' | sudo tee /etc/docker/daemon.json

sudo systemctl restart docker
sleep 15

cd img/vnf-router
sudo docker build -t ceos:4.29.0.2F .
sudo docker tag ceos:4.29.0.2F 192.168.56.11:32000/ceos:latest
sudo docker push 192.168.56.11:32000/ceos:latest

sudo ovs-vsctl add-br PodNet
sudo ifconfig PodNet up

cd ../..
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +

exit 0

