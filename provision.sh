#!/bin/bash
source /vagrant/lib.sh

cd /vagrant/playbooks
#ansible-inventory --list --yaml
ansible-playbook infra-toolbox.yml --diff #-vvv
