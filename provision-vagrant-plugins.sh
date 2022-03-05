#!/bin/bash
source /vagrant/lib.sh

provision_username="${1:-vagrant}"; shift || true
provision_password="${1:-vagrant}"; shift || true

# install the vsphere plugin dependencies.
apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev

# install useful vagrant plugins.
# NB plugins are local to the user.
#    see https://github.com/hashicorp/vagrant/issues/12016
su $provision_username -l -c bash <<'EOF_VAGRANT'
set -euxo pipefail
vagrant plugin install vagrant-vsphere
vagrant plugin install vagrant-windows-sysprep
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-scp
# fix the vagrant scp command to work with windows paths.
# see https://github.com/invernizzi/vagrant-scp/pull/48
pushd ~/.vagrant.d/gems/*/gems/vagrant-scp-*
wget -qO- https://github.com/invernizzi/vagrant-scp/pull/48.patch | patch -p1
popd
EOF_VAGRANT

# if nested virtualization is not available, bail.
if [ -z "$(grep ' vmx ' /proc/cpuinfo)" ]; then
    exit 0
fi

# install the vagrant libvirt plugin.
apt-get install -y libvirt-dev gcc make
su $provision_username -l -c bash <<'EOF_VAGRANT'
set -euxo pipefail
CONFIGURE_ARGS='with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib' \
    vagrant plugin install vagrant-libvirt
EOF_VAGRANT
