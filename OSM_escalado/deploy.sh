#!/bin/bash

microk8s enable registry

sudo touch /etc/docker/daemon.json
echo '{"insecure-registries": ["10.11.12.70:32000"]}' | sudo tee /etc/docker/daemon.json

sudo systemctl restart docker
sleep 15

cd img/vnf-router
sudo docker build -t router .
sudo docker tag router 10.11.12.70:32000/ceos:latest
sudo docker push 10.11.12.70:32000/ceos:latest

sudo ovs-vsctl add-br PodNet1
sudo ifconfig PodNet up

sudo ovs-vsctl add-br PodNet2
sudo ifconfig PodNet up

cd ../..
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64_mejora.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +

# Extract the ID of the first cluster in the table
KID=$(osm k8scluster-list | grep -o "[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}")

# Extract the first UUID from the output
export OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects | grep -o "[a-f0-9]\{8\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{4\}-[a-f0-9]\{12\}" | head -n 1)

echo "export OSMNS='$OSMNS'" >> ~/.bashrc

osm repo-add  --type helm-chart --description "Repo para la practica final de RDSV" helmchartrepo https://aencinas19.github.io/repo-rdsv
osm vnfd-create pck/accessknf_vnfd.tar.gz
osm vnfd-create pck/routerknf_vnfd.tar.gz
osm nsd-create pck/renes_ns.tar.gz
osm vnfd-create pck/accessknf_vnfd2.tar.gz
osm vnfd-create pck/routerknf_vnfd2.tar.gz
osm nsd-create pck/renes_ns2.tar.gz

echo "Add NetowrkAttatchment Definition for PodNet"
microk8s kubectl -n $OSMNS create -f NetAttDefnetPod1.yaml
microk8s kubectl -n $OSMNS create -f NetAttDefnetPod2.yaml

echo "Creating service instances"
echo "Creating renes1"

# Set a variable to check if the command succeeded
status1=1

# Execute the osm ns-create command
export NSID1=$(osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim)

# Start the while loop
while [ $status1 -ne 0 ]
do
    # Wait for 10 seconds before checking if the command succeeded
    echo "Waiting 10 second till instantiating"

    # Check if the command succeeded
        # Get the status of the ns-create
    ns_status1=$(osm ns-list | grep renes1 | tr -d '|' | awk '{print $5}')
    ns_state1=$(osm ns-list | grep renes1 | tr -d '|' | awk '{print $4}')
    echo $ns_status1
    echo $ns_state1
        # Check if the status of the ns-create is IDLE (None)
	if [ "$ns_status1" == "INSTANTIATING" ]; then
	    echo "ns-create not IDLE, trying again in 15 seconds"
	    sleep 15
	    ns_status1=$(osm ns-list | grep renes1 | tr -d '|' | awk '{print $5}')
	    status1=1
	elif [[ "$ns_status1" == "IDLE" && "$ns_state1" != "BROKEN" ]]; then
	    echo "Sucess"
	    status1=0
	else
	    #delete the first process
	    osm ns-delete --force $(eval echo \$NSID1)
	    sleep 5
	    echo "Deleting"
	    # Get the second process
	    export NSID1=$(osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim)
	fi
done

# Print the value of the variable
echo $(eval echo \$NSID1)

status2=1

# Execute the osm ns-create command
export NSID2=$(osm ns-create --ns_name renes2 --nsd_name renes2 --vim_account dummy_vim)

# Start the while loop
while [ $status2 -ne 0 ]
do
    # Wait for 15 seconds before checking if the command succeeded
    echo "Waiting 10 second till instantiating"
    sleep 10

    # Check if the command succeeded
        # Get the status of the ns-create
    ns_status2=$(osm ns-list | grep renes2 | tr -d '|' | awk '{print $5}')
    ns_state2=$(osm ns-list | grep renes2 | tr -d '|' | awk '{print $4}')
    echo $ns_status2
    echo $ns_state2
        # Check if the status of the ns-create is IDLE (None)
	if [ "$ns_status2" == "INSTANTIATING" ]; then
	    echo "ns-create not IDLE, trying again in 15 seconds"
	    sleep 15
	    ns_status2=$(osm ns-list | grep renes2 | tr -d '|' | awk '{print $5}')
	    status2=1
	elif [[ "$ns_status2" == "IDLE" && "$ns_state2" != "BROKEN" ]]; then
	    echo "Sucess"
	    status2=0
	else
	    #delete the first process
	    osm ns-delete --force $(eval echo \$NSID2)
	    sleep 10
	    echo "Deleting"
	    # Get the second process
	    export NSID2=$(osm ns-create --ns_name renes2 --nsd_name renes2 --vim_account dummy_vim)
	fi
done

# Print the value of the variable
echo $(eval echo \$NSID2)

##Configurar renes
echo "Setting up service instances"
./osm_renes1.sh
./osm_renes2.sh

exit 0
