#!/bin/bash

microk8s enable registry
sudo touch /etc/docker/daemon.json
echo '{"insecure-registries": ["192.168.56.11:32000"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
cd img/vnf-img
docker build . -t 192.168.56.11:32000/vnf-image:latest
docker push 192.168.56.11:32000/vnf-image:latest

cd ../..

sudo vnx -f vnx/nfv3_home_lxc_ubuntu64_mejora.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +

ssh upm@192.168.56.12 "./shared/rdsv-final/osm_conf.sh"

exit 0

