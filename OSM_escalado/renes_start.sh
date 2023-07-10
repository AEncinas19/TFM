#!/bin/bash

# Requires the following variables
# KUBECTL: kubectl command
# OSMNS: OSM namespace in the cluster vim
# VACC: "pod_id" or "deploy/deployment_id" of the access vnf
# VCPE: "pod_id" or "deploy/deployment_id" of the cpd vnf
# HOMETUNIP: the ip address for the home side of the tunnel
# VNFTUNIP: the ip address for the vnf side of the tunnel
# VCPEPUBIP: the public ip address for the vcpe
# VCPEGW: the default gateway for the vcpe

set -u # to verify variables are defined
: $KUBECTL
: $OSMNS
: $VACC
: $VROUTER
: $HOMETUNIP
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW
: $MACHX2

ACC_EXEC="$KUBECTL exec -n $OSMNS $VACC --"
ROUTER_EXEC="$KUBECTL exec -n $OSMNS $VROUTER --"

# Router por defecto en red residencial
VCPEPRIVIP="192.168.255.1"

# Router por defecto inicial en k8s (calico)
K8SGW="169.254.1.1"

## 1. Obtener IPs de las VNFs
echo "## 1. Obtener IPs de las VNFs"
IPACCESS=`$ACC_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS = $IPACCESS"

pod_name=`microk8s kubectl -n $OSMNS get all | grep pod/router | tail -n 1 | awk '{print $1}' | tr -d '\r'`

IPROUTER=`microk8s kubectl -n $OSMNS describe $pod_name | grep "IP: " | awk 'NR==2{print $2}'`
echo "IPROUTER = $IPROUTER"

## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF"
$ACC_EXEC service openvswitch-switch start
sleep 5
## 3. En VNF:access agregar un bridge y configurar IPs y rutas
echo "## 3. En VNF:access agregar un bridge y configurar IPs y rutas"
echo "## 3.1 Inicializando Ryu"
$ACC_EXEC ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py &
sleep 5
$ACC_EXEC ovs-vsctl add-br brint
$ACC_EXEC ovs-vsctl set bridge brint protocols=OpenFlow10,OpenFlow12,OpenFlow13
$ACC_EXEC ovs-vsctl set-fail-mode brint secure
$ACC_EXEC ovs-vsctl set bridge brint other-config:datapath-id=0000000000000001
$ACC_EXEC ifconfig net1 $VNFTUNIP/24
$ACC_EXEC ip link add vxlanacc type vxlan id 0 remote $HOMETUNIP dstport 4789 dev net1
$ACC_EXEC ip link add vxlanint type vxlan id 1 remote 172.16.0.1 dstport 4789 dev eth1
$ACC_EXEC ovs-vsctl add-port brint vxlanacc
$ACC_EXEC ovs-vsctl add-port brint vxlanint
$ACC_EXEC ifconfig vxlanacc up
$ACC_EXEC ifconfig vxlanint up
$ACC_EXEC ovs-vsctl set-controller brint tcp:127.0.0.1:6633
$ACC_EXEC ovs-vsctl set-manager ptcp:6632
$ACC_EXEC ip route del 0.0.0.0/0 via $K8SGW
$ACC_EXEC ip route add 0.0.0.0/0 via 10.0.0.2
$ACC_EXEC ip route add 10.1.77.0/24 via $K8SGW
$ACC_EXEC ./node_exporter-1.5.0.linux-amd64/node_exporter &

## 4. En VNF:router activar NAT para dar salida a Internet
sleep 10
$ROUTER_EXEC ./mnt/flash/vnx_config_nat vlan1 eth2

## 5. Configurar colas
$ACC_EXEC curl -X PUT -d '"tcp:127.0.0.1:6632"' http://127.0.0.1:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr
$ACC_EXEC curl -X POST -d '{"port_name": "vxlanacc", "type": "linux-htb", "max_rate": "3000000", "queues": [{"max_rate": "3000000"},{ "min_rate": "1000000"}]}' http://127.0.0.1:8080/qos/queue/0000000000000001
$ACC_EXEC curl -X POST -d '{"match": {"dl_dst": "'$MACHX2'", "dl_type": "IPv4"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000001
$ACC_EXEC curl -X POST -d '{"match": {"dl_dst": "'$MACHX1'", "dl_type": "IPv4"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000001
$ACC_EXEC curl -X POST -d '{"port_name": "vxlanint", "type": "linux-htb", "max_rate": "3000000", "queues": [{"min_rate": "3000000"},{"min_rate": "1000000"}]}' http://127.0.0.1:8080/qos/queue/0000000000000001
$ACC_EXEC curl -X POST -d '{"match": {"dl_src": "'$MACHX2'", "dl_type": "IPv4"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000001
$ACC_EXEC curl -X POST -d '{"match": {"dl_src": "'$MACHX1'", "dl_type": "IPv4"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000001

## 6. Configurar interfaz de gestión
cd ../AristacEOS
echo "Setting Mgmt0's IP interface"
echo $(eval echo \$IPROUTER)
source ./config-mgmt-iface-arista.sh $VROUTER $IPROUTER $OSMNS

