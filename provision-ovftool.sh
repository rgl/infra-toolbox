#!/bin/bash
set -euxo pipefail

# see https://github.com/rgl/ovftool-binaries
version='4.4.3-18663434'
url="https://github.com/rgl/ovftool-binaries/raw/main/archive/VMware-ovftool-$version-lin.x86_64.zip"
wget -q -O /tmp/ovftool.zip $url
unzip -q -d /opt /tmp/ovftool.zip
rm /tmp/ovftool.zip
ln -fs /etc/ssl/certs/ca-certificates.crt /opt/ovftool/certs/cacert.pem
ln -fs /opt/ovftool/ovftool /usr/local/bin/
ovftool --version
