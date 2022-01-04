#!/bin/bash
set -euxo pipefail

terraform_version='1.1.3'                     # see https://github.com/hashicorp/terraform/releases
ansible_terraform_inventory_version='2.2.0'   # see https://github.com/nbering/terraform-inventory/releases

# install terraform.
wget -q https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_linux_amd64.zip
unzip terraform_${terraform_version}_linux_amd64.zip
install \
  -m 755 \
  terraform \
  /usr/local/bin
rm terraform terraform_${terraform_version}_linux_amd64.zip

# install the ansible terraform dynamic inventory provider.
wget -q https://github.com/nbering/terraform-inventory/releases/download/v$ansible_terraform_inventory_version/terraform.py
# make it use the python3 binary instead of just python.
sed -i -E 's,#!.+,#!/usr/bin/python3,' terraform.py
# fix the following error/warning:
#   /etc/ansible/terraform.py:390: DeprecationWarning: 'encoding' is ignored and deprecated. It will be removed in Python 3.9   return json.loads(out_cmd, encoding=encoding)
sed -i -E 's/return json.loads\(out_cmd, encoding=encoding\)/return json.loads(out_cmd)/g' terraform.py
# install it.
install \
  -m 755 \
  terraform.py \
  /etc/ansible/terraform.py
rm terraform.py
