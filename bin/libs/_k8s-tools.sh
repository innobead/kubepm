#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh
# shellcheck disable=SC1090
source "${LIB_DIR}"/_dev.sh

# Constants
KUBE_VERSION=${KUBE_VERSION:-$(k8s_version)}
KIND_VERSION=${KIND_VERSION:-}
HELM_VERSION=${HELM_VERSION:-}
MINIKUBE_VERSION=${MINIKUBE_VERSION:-}
VELERO_VERSION=${VELERO_VERSION:-}
FOOTLOOSE_VERSION=${FOOTLOOSE_VERSION:-}
KREW_VERSION=${KREW_VERSION:-}
SKAFFOLD_VERSION=${SKAFFOLD_VERSION:-}
CTRLTOOLS_VERSION=${CTRLTOOLS_VERSION:-}
KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION:-}

function install_kind() {
  repo_path=kubernetes-sigs/kind \
    version="$KIND_VERSION" \
    download_url="v{VERSION}/kind-linux-amd64" \
    exec_name=kind \
    exec_version_cmd="version" \
    install_github_pkg
}

function install_minikube() {
  if ! grep -E --color 'vmx|svm' /proc/cpuinfo; then
    echo "No virtualization is supported."
    exit 1
  fi

  repo_path=kubernetes/minikube \
    version="$MINIKUBE_VERSION" \
    download_url="v{VERSION}/minikube-linux-amd64" \
    exec_name=minikube \
    exec_version_cmd="version" \
    install_github_pkg

  cat <<EOF
If using kvm2 as vm-driver, please make sure default network is NAT to avoid unability to access internet to download necessary container images.

➜  ~ virsh net-dumpxml default
<network>
  <name>default</name>
  <uuid>13035582-7a70-4be0-804f-c00098f39e02</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:20:b9:fc'/>
  <domain name='default'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.128' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF
}

function install_helm() {
  if [[ -z $HELM_VERSION ]]; then
    HELM_VERSION=$(git_release_version helm/helm)
  fi

  # shellcheck disable=SC2076
  if [[ "$HELM_VERSION" =~ ^v2 ]] && check_cmd helm2 && [[ "$(helm2 version --client)" =~ "$HELM_VERSION" ]]; then
    return
  elif [[ "$HELM_VERSION" =~ ^v3 ]] && check_cmd helm && [[ "$(helm version --client)" =~ "$HELM_VERSION" ]]; then
    return
  fi

  pushd "${KU_TMP_DIR}"

  download=helm-$HELM_VERSION-linux-amd64.tar.gz
  curl -sSfLO "https://get.helm.sh/$download" &&
    tar -zxvf "$download" --strip-components 1 && rm "$download"

  chmod +x helm

  if [[ "$HELM_VERSION" =~ ^v2 ]]; then
    sudo mv helm /usr/local/bin/helm2
  elif [[ "$HELM_VERSION" =~ ^v3 ]]; then
    sudo mv helm /usr/local/bin/
  fi

  helm repo add stable https://kubernetes-charts.storage.googleapis.com

  popd
}

function install_kubectl() {
  # shellcheck disable=SC2076
  if ! check_cmd kubectl || [[ ! "$(kubectl version --client)" =~ "$KUBE_VERSION" ]]; then
    pushd "${KU_TMP_DIR}"
    # shellcheck disable=SC2086
    curl -sSfLO "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl" &&
      sudo install kubectl "$KU_INSTALL_BIN"
    popd
  fi
}

function install_velero() {
  repo_path=vmware-tanzu/velero \
    version="$VELERO_VERSION" \
    download_url="v{VERSION}/velero-v{VERSION}-linux-amd64.tar.gz" \
    exec_name=velero \
    exec_version_cmd="version --client-only" \
    install_github_pkg
}

# krew is a tool that makes it easy to use kubectl plugins. Ref: https://github.com/kubernetes-sigs/krew
function install_krew() {
  install_kubectl

  if [[ -z $KREW_VERSION ]]; then
    KREW_VERSION=$(git_release_version kubernetes-sigs/krew)
  fi

  pushd "${KU_TMP_DIR}"
  if ! check_cmd krew || [[ ! "$(krew version)" =~ $KUBE_VERSION ]]; then
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/$KREW_VERSION/krew.{tar.gz,yaml}" &&
      tar zxvf krew.tar.gz &&
      KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" && mv "$KREW" "$KU_INSTALL_BIN"/krew
    krew install --manifest=krew.yaml --archive=krew.tar.gz &&
      krew update

    rm -rf krew*
  fi

  plugins_path=${KREW_ROOT:-$HOME/.krew}/bin

  rcs=("$HOME/.bashrc" "$HOME/.zshrc")
  for i in "${rcs[@]}"; do
    if [[ -f "$i" ]] && [[ ! "$(cat "$i")" =~ $plugins_path ]]; then
      cat <<EOF >>"$i"
export PATH=\$PATH:$plugins_path
EOF
    fi
  done

  popd
}

function install_kubebuilder() {
  repo_path=kubernetes-sigs/kubebuilder \
    version="$KUBEBUILDER_VERSION" \
    download_url="v{VERSION}/kubebuilder_{VERSION}_linux_amd64.tar.gz" \
    exec_name=kubebuilder \
    exec_version_cmd="version" \
    install_github_pkg
}

function install_controllertools() {
  if [[ -z $CTRLTOOLS_VERSION ]]; then
    CTRLTOOLS_VERSION=$(git_release_version kubernetes-sigs/controller-tools)
  fi

  go get sigs.k8s.io/controller-tools/cmd/controller-gen@"$CTRLTOOLS_VERSION"
}

function install_kustomize() {
  if [[ -z $KUSTOMIZE_VERSION ]]; then
    KUSTOMIZE_VERSION=$(
      curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases |
        grep browser_download |
        grep linux |
        cut -d '"' -f 4 |
        grep /kustomize/v |
        sort |
        tail -n 1 |
        xargs basename |
        awk -F _ '{print $2}'
    )
  fi

  repo_path=kubernetes-sigs/kustomize \
    version="$KUSTOMIZE_VERSION" \
    download_url="kustomize/{VERSION}/kustomize_{VERSION}_linux_amd64.tar.gz" \
    exec_name=kustomize \
    exec_version_cmd="version --short" \
    install_github_pkg
}

function install_ignite() {
  # https://ignite.readthedocs.io/en/stable/installation.html

  if ! lscpu | grep Virtualization || ! lsmod | grep kvm; then
    error "No virtualization supported"
  fi

  if ! command -v containerd; then
    error "No docker installed"
  fi

  zypper in "$KU_ZYPPER_INSTALL_OPTS" e2fsprogs openssh git

  install_cni_plugins

  repo_path=weaveworks/ignite \
    version="$IGNITE_VERSION" \
    download_url="v{VERSION}/ignite-amd64,v{VERSION}/ignited-amd64" \
    exec_name="ignite,ignited" \
    exec_version_cmd="version -o short" \
    install_github_pkg
}

# footloose creates containers that look like virtual machines. Ref: https://github.com/weaveworks/footloose
function install_footloose() {
  repo_path=weaveworks/footloose \
    version="$FOOTLOOSE_VERSION" \
    download_url="{VERSION}/footloose-{VERSION}-linux-x86_64" \
    exec_name=footloose \
    exec_version_cmd="version | head -n 1 | awk -F : '{print \$2}' | tr -d ' '" \
    install_github_pkg
}

function install_cni_plugins() {
  repo_path=containernetworking/plugins\
    download_url="v{VERSION}/cni-plugins-linux-amd64-v{VERSION}.tgz" \
    dest_dir="/opt/cni/bin" \
    install_github_pkg
}
