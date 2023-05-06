#!/bin/bash
OSMNS="$3"
pod_name="$1"
IP_address="$2"/24
microk8s kubectl -n $OSMNS exec -it $pod_name -- Cli -p 15 -c "bash ./mnt/flash/vnx_config_nat vlan1 eth2"
microk8s kubectl -n $OSMNS exec -it $pod_name -- Cli -p 15 -c "configure terminal
interface Management0
ip address $IP_address
end
"
