cd ../Prometheus_k8s

microk8s kubectl create ns monitoring

microk8s kubectl create -f cadvisor.yaml

microk8s kubectl create -f config-map.yaml
microk8s kubectl create -f prometheus-deployment.yaml
microk8s kubectl create -f prometheus-service.yaml
microk8s kubectl create -f cadvisor.yaml

cd ../AristacEOS/monitoring
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml

cd ../../Grafana
microk8s kubectl create -f config-map.yaml
microk8s kubectl create -f persistentvolume.yaml
microk8s kubectl create -f pvc.yaml
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml

cd ../Kafka
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml
