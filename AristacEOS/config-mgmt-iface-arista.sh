#!/bin/bash
pod_name="$1"
IP_address="$2"
kuecetl exec -it $pod_name -- Cli -p 15 -c "configure terminal
interface Management0
ip address $IP_address
"
