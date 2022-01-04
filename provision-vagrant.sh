#!/bin/bash
set -euxo pipefail

provision_username="$1"; shift
provision_password="$1"; shift

# install Vagrant.
# see https://github.com/hashicorp/vagrant/tags.
vagrant_version='2.2.19'
wget -q -O/tmp/vagrant_${vagrant_version}_x86_64.deb https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}_x86_64.deb
dpkg -i /tmp/vagrant_${vagrant_version}_x86_64.deb
rm /tmp/vagrant_${vagrant_version}_x86_64.deb

# make vagrant use the system ca certificates.
cat >/etc/profile.d/env-ssl-cert-file.sh <<'EOF'
# make sure vagrant uses the system ca-certificates.
# NB by default vagrant uses /opt/vagrant/embedded/cacert.pem, which
#    we do not want to modify.
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
EOF

# add support for smb shared folders.
# see https://github.com/hashicorp/vagrant/pull/9948
pushd /opt/vagrant/embedded/gems/$vagrant_version/gems/vagrant-$vagrant_version
wget -q https://github.com/hashicorp/vagrant/commit/ed7139fa1e896d0b84ed32180b72a647bf9f37eb.patch
patch -p1 <ed7139fa1e896d0b84ed32180b72a647bf9f37eb.patch
rm ed7139fa1e896d0b84ed32180b72a647bf9f37eb.patch
popd
apt-get install -y samba smbclient
# modify the samba configuration to allow symlinks outside of the share path.
python3 <<'EOF'
smb_conf_path = '/etc/samba/smb.conf'
config = open(smb_conf_path).read()
config = config.replace('[global]', '''\
[global]
# allow the creation and use of symlinks outside of the share path to
# anywhere of the host filesystem.
# NB this is used by orchestra product repo.
allow insecure wide links = yes
follow symlinks = yes
wide links = yes
''')
# prevent users without accounts from logging in.
config = config.replace('map to guest = bad user', 'map to guest = never')
open(smb_conf_path, 'w').write(config)
EOF
systemctl reload smbd
# set the share password.
smbpasswd -a -s $provision_username <<EOF
$provision_password
$provision_password
EOF

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
EOF_VAGRANT
