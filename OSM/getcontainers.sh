#!/bin/bash
KID=$(osm k8scluster-list | grep -o "[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}")
export OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects | grep -o "[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}" | head -n 1)

export router_name=$(microk8s kubectl -n $OSMNS get all | grep pod/router | tail -n 1 | awk '{print $1}' | tr -d '\r')
export accesspod_name=$(microk8s kubectl -n $OSMNS get all | grep pod/accesspod | tail -n 1 | awk '{print $1}' | tr -d '\r')

export access_container_id=$(microk8s kubectl -n $OSMNS describe $accesspod_name | grep -oP '(?<=containerd://)[a-f0-9]+')
export router_container_id=$(microk8s kubectl -n $OSMNS describe $router_name | grep -oP '(?<=containerd://)[a-f0-9]+')

export access_container=$(curl -sl localhost:32200/metrics | grep $access_container_id | awk -F '/' '{print "/"$4"/"$5}' | tail -n 1 | grep -oE '^([^"\]+)')
export router_container=$(curl -sl localhost:32200/metrics | grep $router_container_id | awk -F '/' '{print "/"$4"/"$5}' | tail -n 1)

echo "Access pod: $access_container"
echo "Router: $router_container"


cd ../Grafana
access_container_prev_grafana=$(cat dashboard.json | grep -B 10 'Access' |  grep kubepods/besteffort/pod | awk -F '/' '{print "/"$4"/"$5}' | grep -oE '^([^"\]+)' | tail -n 1)
router_container_prev_grafana=$(cat dashboard.json | grep -B 10 'Router' |  grep kubepods/besteffort/pod | awk -F '/' '{print "/"$4"/"$5}' | grep -oE '^([^"\]+)' | tail -n 1)
sed -i "s|$access_container_prev_grafana|$access_container|g" dashboard.json
sed -i "s|$router_container_prev_grafana|$router_container|g" dashboard.json

cd ../Prometheus_k8s
router_container_prev_prometheus=$(cat config-map.yaml | grep -B 10 'Router' |  grep kubepods/besteffort/pod | awk -F '/' '{print "/"$4"/"$5}' | grep -oE '^([^"\]+)' | tail -n 1)
sed -i "s|$router_container_prev_prometheus|$router_container|g" config-map.yaml
