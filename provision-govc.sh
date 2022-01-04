#!/bin/bash
set -euxo pipefail

# see https://github.com/vmware/govmomi/releases
govc_version='0.27.2'
govc_url="https://github.com/vmware/govmomi/releases/download/v$govc_version/govc_Linux_x86_64.tar.gz"
govc_archive="$(basename "$govc_url")"
wget -q "$govc_url"
tar xf "$govc_archive" govc
install -m 755 govc /usr/local/bin
rm -f govc "$govc_archive"
