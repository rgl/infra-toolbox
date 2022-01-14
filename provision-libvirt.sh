#!/bin/bash
source /vagrant/lib.sh

# if nested virtualization is not available, bail.
if [ -z "$(grep ' vmx ' /proc/cpuinfo)" ]; then
    exit 0
fi

# install libvirt.
apt-get install -y libvirt-daemon-system

# configure the security_driver to prevent errors alike (when using terraform):
#   Could not open '/var/lib/libvirt/images/terraform_example_root.img': Permission denied'
sed -i -E 's,#?(security_driver)\s*=.*,\1 = "none",g' /etc/libvirt/qemu.conf
systemctl restart libvirtd

# let the vagrant user manage libvirtd.
# see /usr/share/polkit-1/rules.d/60-libvirt.rules
usermod -aG libvirt vagrant
