#! /bin/bash

echo "destroy-aio.sh: #############################################################"
echo "destroy-aio.sh  #                                                           #"
echo "destroy-aio.sh: # THIS SCRIPT WILL DESTROY CURRENT OpenStack DEPLOYMENT !!! #"
echo "destroy-aio.sh: #                                                           #"
echo "destroy-aio.sh: #############################################################"
echo "destroy-aio.sh:"
printf "destroy-aio.sh: Please enter 'yes-i-want-it' to confirm: "; read ANSWER
if [ ! $ANSWER = 'yes-i-want-it' ]
then
  echo "Uff... I'm saved. Exiting..."
  exit
fi

# Move to the playbooks directory.
cd /opt/openstack-ansible/playbooks

# Destroy all of the running containers.
openstack-ansible lxc-containers-destroy.yml

# On the host stop all of the services that run locally and not
#  within a container.
for i in $(ls /etc/init | grep -e "nova\|swift\|neutron\|cinder" | awk -F'.' '{print $1}') 
do
   service $i stop
done

# Uninstall the core services that were installed.
for i in $(pip freeze | grep -e "nova\|neutron\|keystone\|swift\|cinder")
do
  pip uninstall -y $i
done

# Remove crusty directories.
rm -rf /openstack /etc/{neutron,nova,swift,cinder} /var/log/{neutron,nova,swift,cinder}

# Remove the pip configuration files on the host
rm -rf /root/.pip

# Remove the apt package manager proxy
rm /etc/apt/apt.conf.d/00apt-cacher-proxy

echo "destroy-aio.sh: OpenStack Deployment destroyed"
