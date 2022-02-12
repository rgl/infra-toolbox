#!/bin/bash
set -euxo pipefail

# NB execute apt-cache madison azure-cli to known the available versions.
# see https://github.com/Azure/azure-cli/releases
azure_cli_version='2.33.0'

# install dependencies.
apt-get install -y apt-transport-https gnupg

# install azure-cli.
# see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
cat >/etc/apt/sources.list.d/azure-cli.list <<EOF
deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main
EOF
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
apt-get update
apt-cache madison azure-cli | head -10 || true
azure_cli_package_version="$(apt-cache madison azure-cli | awk "/$azure_cli_version-/{print \$3}")"
apt-get install -y azure-cli="$azure_cli_package_version"
az --version
