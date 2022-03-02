#!/bin/bash
source /vagrant/lib.sh

# see https://github.com/kubernetes/kubernetes/releases
# see https://kubernetes.io/releases/
kubernetes_version="${1:-1.23.4}"; shift || true

# install.
# see https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
wget -qO /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo 'deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' >/etc/apt/sources.list.d/kubernetes.list
apt-get update
kubectl_package_version="$(apt-cache madison kubectl | awk "/$kubernetes_version-/{print \$3}")"
apt-get install -y "kubectl=$kubectl_package_version"
kubectl completion bash >/usr/share/bash-completion/completions/kubectl
kubectl version --client
