#!/bin/bash
set -euxo pipefail

# see https://github.com/hashicorp/packer/releases
packer_version='1.7.9'
wget -q -O/tmp/packer_${packer_version}_linux_amd64.zip https://releases.hashicorp.com/packer/${packer_version}/packer_${packer_version}_linux_amd64.zip
unzip /tmp/packer_${packer_version}_linux_amd64.zip -d /usr/local/bin
