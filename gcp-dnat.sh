#! /bin/bash

# When deploying on GCP VM, configure DNAT from VM Internal IP address to OpenStack VIP address

myip=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F -t nat
iptables -t nat  -A PREROUTING -d $myip/32 -p tcp -m tcp --syn -m multiport --dports 80,443,6082 -j DNAT --to-destination 172.29.236.100
