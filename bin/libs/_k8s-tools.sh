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
  if [[ -z $KIND_VERSION ]]; then
    KIND_VERSION=$(git_release_version kubernetes-sigs/kind)
  fi

  if ! check_cmd kind || [[ ! "$(kind version)" != "$KIND_VERSION" ]]; then
    pushd "${KU_TMP_DIR}"
    curl -sSfL -o kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64" &&
      sudo install kind "$KU_INSTALL_BIN"
    popd
  fi
}

function install_minikube() {
  if ! grep -E --color 'vmx|svm' /proc/cpuinfo; then
    echo "No virtualization is supported."
    exit 1
  fi

  if [[ -z $MINIKUBE_VERSION ]]; then
    MINIKUBE_VERSION=$(git_release_version kubernetes/minikube)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd minikube || [[ ! "$(minikube version)" =~ "$MINIKUBE_VERSION" ]]; then
    curl -sSfL -o minikube "https://github.com/kubernetes/minikube/releases/download/$MINIKUBE_VERSION/minikube-linux-amd64" &&
      sudo install minikube "$KU_INSTALL_BIN"
  fi

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
  if [[ -z $VELERO_VERSION ]]; then
    VELERO_VERSION=$(git_release_version vmware-tanzu/velero)
  fi

  if ! command -v velero || [[ "$(velero version --client-only)" != "$VELERO_VERSION" ]]; then
    f="velero-$VELERO_VERSION-linux-amd64.tar.gz"
    curl -sSfL -O "https://github.com/vmware-tanzu/velero/releases/download/$VELERO_VERSION/$f"

    mkdir velero &&
      tar zxvf "$f" --strip-components=1 -C velero &&
      rm "$f"

    chmod +x velero/velero && sudo mv velero/velero /usr/local/bin/
  fi
}

# footloose creates containers that look like virtual machines. Ref: https://github.com/weaveworks/footloose
function install_footloose() {
  if [[ -z $FOOTLOOSE_VERSION ]]; then
    FOOTLOOSE_VERSION=$(git_release_version weaveworks/footloose)
  fi

  if ! command -v footloose || [[ ! "$(footloose version | awk '{print $2}')" =~ $FOOTLOOSE_VERSION ]]; then
    curl -sSfL -o footloose "https://github.com/weaveworks/footloose/releases/download/$FOOTLOOSE_VERSION/footloose-$FOOTLOOSE_VERSION-linux-x86_64"
    chmod +x footloose && sudo mv footloose /usr/local/bin
  fi
}

# krew is a tool that makes it easy to use kubectl plugins. Ref: https://github.com/kubernetes-sigs/krew
function install_krew() {
  install_kubectl

  if [[ -z $KREW_VERSION ]]; then
    KREW_VERSION=$(git_release_version kubernetes-sigs/krew)
  fi

  pushd "${KU_TMP_DIR}"
  if ! check_cmd krew || [[ ! "$(krew version)" =~ "$KUBE_VERSION" ]]; then
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
    if [[ -f "$i" ]] && [[ ! "$(cat "$i")" =~ "$plugins_path" ]]; then
      cat <<EOF >>"$i"
export PATH=\$PATH:$plugins_path
EOF
    fi
  done

  popd
}

function install_skaffold() {
  install_kubectl

  if [[ -z $SKAFFOLD_VERSION ]]; then
    SKAFFOLD_VERSION=$(git_release_version GoogleContainerTools/skaffold)
  fi

  pushd "${KU_TMP_DIR}"
  if ! check_cmd skaffold || [[ ! "$(skaffold version)" =~ "$SKAFFOLD_VERSION" ]]; then
    curl -fsSL -o skaffold "https://github.com/GoogleContainerTools/skaffold/releases/download/$SKAFFOLD_VERSION/skaffold-linux-amd64"
    chmod +x skaffold
    sudo mv skaffold /usr/local/bin
  fi
  popd
}

function install_kubebuilder() {
  install_go

  if [[ -z $KUBEBUILDER_VERSION ]]; then
    KUBEBUILDER_VERSION=$(git_release_version kubernetes-sigs/kubebuilder)
  fi

  if ! check_cmd kubebuilder || [[ ! "$(kubebuilder version)" =~ "${KUBEBUILDER_VERSION:1}" ]]; then
    os=$(go env GOOS)
    arch=$(go env GOARCH)

    pushd "${KU_TMP_DIR}"
    mkdir kubebuilder || true
    curl -fsSL "https://github.com/kubernetes-sigs/kubebuilder/releases/download/${KUBEBUILDER_VERSION}/kubebuilder_${KUBEBUILDER_VERSION:1}_${os}_${arch}.tar.gz" |
      tar zxv --strip-components=1 -C kubebuilder

    # kubebuilder also exists with other executables
    #  ➜  ~ ll ~/Downloads/kubebuilder_2.2.0_linux_amd64/bin/ | awk '{if(NF>2){print $9}}'
    #etcd
    #kube-apiserver
    #kubebuilder
    #kubectl
    install kubebuilder/bin/kubebuilder "$KU_INSTALL_BIN" && rm -rf kubebuilder

    popd
  fi
}

function install_controllertools() {
  install_go

  if [[ -z $CTRLTOOLS_VERSION ]]; then
    CTRLTOOLS_VERSION=$(git_release_version kubernetes-sigs/controller-tools)
  fi

  go get sigs.k8s.io/controller-tools/cmd/controller-gen@"$CTRLTOOLS_VERSION"
}

function install_kustomize() {
  install_go

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

  pushd "${KU_TMP_DIR}"

  if ! check_cmd kustomize || [[ ! "$(kustomize version --short)" =~ "${KUSTOMIZE_VERSION:1}" ]]; then
    curl -sSfL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar zxv
    install kustomize "$KU_INSTALL_BIN" && rm -rf kustomize
  fi

  popd
}
