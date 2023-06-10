cd ../Prometheus_k8s

echo "Creando namespace"
microk8s kubectl create ns monitoring

echo "Instanciando prometheus"
microk8s kubectl create -f config-map.yaml
microk8s kubectl create -f prometheus-deployment.yaml
microk8s kubectl create -f prometheus-service.yaml

echo "Instanciando pushgateway"
microk8s kubectl create -f pushgw.yaml


echo "Instanciando cadvisor"
microk8s kubectl create -f cadvisor.yaml
microk8s kubectl create -f cadvisor-service.yaml

echo "Instanciando cliente gnmi"
cd ../AristacEOS/monitoring
docker build -t 10.11.12.70:32000/gnmic .
docker push 10.11.12.70:32000/gnmic:latest
microk8s kubectl -n monitoring create -f deployment.yaml
microk8s kubectl -n monitoring create -f service.yaml
sleep 10
source exec_templates.sh


echo "Instanciando grafana"
cd ../../Grafana
microk8s kubectl create -f config-map.yaml
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml

echo "Instanciando kafka"
cd ../Kafka
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml

echo "Instanciando flink"
cd FlinkOperatorEth1
# Instalar cert-manager para automatizar la gestión de certificados en el cluster Kubernetes:
microk8s kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
# Instalar Flink-Operator de spotify:
microk8s kubectl apply -f https://github.com/spotify/flink-on-k8s-operator/releases/download/v0.3.9/flink-operator.yaml
# Despliegue de clusters de Flink:
docker build -t 10.11.12.70:32000/traffic-rate .
docker push 10.11.12.70:32000/traffic-rate:latest
cd flink-helm
microk8s helm3 -n monitoring install flink-applications . --values ./values.yaml

echo "Instanciando AlertManager"
cd ../../../AlertManager
microk8s kubectl create -f configmap.yaml
microk8s kubectl create -f deployment.yaml
microk8s kubectl create -f service.yaml
