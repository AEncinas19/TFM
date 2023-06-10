#!/bin/bash
pod_name=$(microk8s kubectl -n monitoring get all | grep pod/gnmi-client | tail -n 1 | awk '{print $1}' | tr -d '\r')


microk8s kubectl -n monitoring exec $pod_name -- gnmic --config subscription-template-gnmic-eth1.json subscribe &
microk8s kubectl -n monitoring exec $pod_name -- gnmic --config subscription-template-gnmic-eth2.json subscribe &
