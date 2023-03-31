#!/bin/bash

microk8s enable registry

sudo touch /etc/docker/daemon.json
echo '{"insecure-registries": ["192.168.56.11:32000"]}' | sudo tee /etc/docker/daemon.json

sudo systemctl restart docker

sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +

ssh upm@192.168.56.12 "./TFM/OSM/osm_conf.sh"

exit 0

