#! /bin/bash

echo "run-osa-aio.sh: Cloning OpenStack Ansible repo"
git clone https://git.openstack.org/openstack/openstack-ansible /opt/openstack-ansible
cd /opt/openstack-ansible

echo "run-osa-aio.sh: Checking out Queens (17.0.6)"
git checkout 17.0.6

echo "run-osa-aio.sh: Please review and update bootstrap-host role defaults"
echo "run0osa-aio.sh: Consider changing 'bootstrap_host_loopback_cinder' to 'no', if cinder_volumes VG is already created"
echo "run-osa-aio.sh: Hit <Enter> to launch 'vim tests/roles/bootstrap-host/defaults/main.yml'"; read ANSWER
vim tests/roles/bootstrap-host/defaults/main.yml

echo "run-osa-aio.sh: Running scripts/bootstrap-ansible.sh"
scripts/bootstrap-ansible.sh

if [ $? -ne 0 ]; then
  echo "run-osa-aio.sh: scripts/bootstrap-ansible.sh failed! Exiting..."
  exit $?
fi

printf "run-osa-aio.sh: Do you want to remove Designate from the Scenario? [y/n]: "; read ANSWER
if [ $ANSWER = 'y' ]
then
  mv /etc/openstack_deploy/conf.d/designate.yml /etc/openstack_deploy/conf.d/designate.yml.old.$(date '+%s')
fi

echo "run-osa-aio.sh: Running scripts/bootstrap-aio.sh with 'aio_lxc' scenario"
export SCENARIO='aio_lxc'
scripts/bootstrap-aio.sh

if [ $? -ne 0 ]; then
  echo "run-osa-aio.sh: scripts/bootstrap-aio.sh failed! Exiting..."
  exit $?
fi

echo "run-osa-aio.sh: Do you want to install OpenStack Telemetry (aodh, gnocchi, ceilometer)? [y/n]:"
read ANSWER
if [ $ANSWER = y ]
then
  echo "run-osa-aio.sh: Adding aodh, gnocchi and ceilometer to AIO configuration"
  cd /opt/openstack-ansible/
  cp etc/openstack_deploy/conf.d/{aodh,gnocchi,ceilometer}.yml.aio /etc/openstack_deploy/conf.d/
  for f in $(ls -1 /etc/openstack_deploy/conf.d/*.aio); do mv -v ${f} ${f%.*}; done
fi

for config_file in /etc/network/intefaces.d/osa_interfaces.cfg /etc/openstack_deploy/user_variables.yml /etc/openstack_deploy/openstack_user_config.yml /etc/openstack_deploy/user_secrets.yml
do
  echo "run-osa-aio.sh: Please review $config_file"
  config_file_old=$config_file.old.$(date '+%s')
  echo "run-osa-aio.sh: Saving current version of the file in $config_file_old"
  echo "run-osa-aio.sh: Press <Enter> to continue"; read ANSWER
  cp $config_file $config_file_old
  vim $config_file
done

cd /opt/openstack-ansible/playbooks

for playbook in setup-hosts.yml setup-infrastructure.yml setup-openstack.yml
do
  echo "run-osa-aio.sh: Running openstack-ansible $playbook"
  openstack-ansible $playbook
  if [ $? -ne 0 ]; then
    echo "run-osa-aio.sh: openstack-ansible $playbook failed! Exiting..."
    exit $?
  fi
done

echo "run-osa-aio.sh" OpenStack is deployed :)"
