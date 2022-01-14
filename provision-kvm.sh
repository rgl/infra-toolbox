#!/bin/bash
source /vagrant/lib.sh

# if nested virtualization is not available, bail.
if [ -z "$(grep ' vmx ' /proc/cpuinfo)" ]; then
    exit 0
fi

apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v

# let the vagrant user manage kvm.
usermod -aG kvm vagrant
