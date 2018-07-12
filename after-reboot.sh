#! /bin/bash

cd /opt/openstack-ansible/playbooks
echo "after-reboot.sh: Fixing Galera Cluster state..."
openstack-ansible -e galera_ignore_cluster_state=true galera-install.yml
