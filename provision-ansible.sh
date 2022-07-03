#!/bin/bash
source /vagrant/lib.sh

# make sure the package index cache is up-to-date before installing anything.
apt-get update

# install ansible.
# see https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-with-pip
apt-get install -y --no-install-recommends \
    python3-pip \
    python3-cryptography \
    python3-openssl \
    python3-yaml \
    pylint \
    sshpass
# NB this pip install will display several "error: invalid command 'bdist_wheel'"
#    messages, those can be ignored.
python3 -m pip install \
    -r /vagrant/ansible-requirements.txt
ansible-galaxy collection install \
    -r /vagrant/ansible-requirements.yml \
    -p /usr/share/ansible/collections
install -d -m 755 /etc/ansible
install -m 644 /vagrant/ansible.cfg /etc/ansible
ansible --version
python3 -m pip list
ansible-galaxy collection list
ansible -m ping localhost

# install the ansible shell completion helpers.
if [ ! -v GITHUB_ACTIONS ]; then
install -d /etc/bash_completion.d
apt-get install -y python3-argcomplete
activate-global-python-argcomplete3
fi
