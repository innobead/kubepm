#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Constants
KUBE_VERSION=${KUBE_VERSION:-$(k8s_version)}
KIND_VERSION=${KIND_VERSION:-v0.6.1}
HELM_VERSION=${HELM_VERSION:-v2.14.3}
MKCERT_VERSION=${MKCERT_VERSION:-v1.4.0}
MINIKUBE_VERSION=${MINIKUBE_VERSION:-v1.5.0}

function install_kind() {
  if ! check_cmd kind || "$(kind version)" != "$KIND_VERSION"; then
    pushd /tmp
    curl -L -o kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64" &&
      chmod +x kind &&
      mv kind /usr/local/bin/
    popd
  fi
}

function install_minikube() {
  if ! grep -E --color 'vmx|svm' /proc/cpuinfo; then
    echo "No virtualization is supported."
    exit 1
  fi

  # shellcheck disable=SC2076
  if ! check_cmd minikube || [[ "$(minikube version)" =~ "$MINIKUBE_VERSION" ]]; then
    curl -Lo minikube "https://storage.googleapis.com/minikube/releases/$MINIKUBE_VERSION/minikube-linux-amd64" &&
      chmod +x minikube &&
      mv minikube /usr/local/bin/
  fi
}

function install_helm() {
  # shellcheck disable=SC2076
  if ! check_cmd helm || [[ "$(helm version --client)" =~ "$HELM_VERSION" ]]; then
    pushd /tmp
    curl -LO "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" &&
      tar -zxvf helm-*.tar.gz --strip-components 1 &&
      chmod +x helm &&
      mv helm /usr/local/bin/
    popd
  fi
}

function install_mkcert() {
  if ! check_cmd mkcert; then
    pushd /tmp
    curl -L -o mkcert "https://github.com/FiloSottile/mkcert/releases/download/$MKCERT_VERSION/mkcert-$MKCERT_VERSION-linux-amd64" &&
      chmod +x mkcert &&
      mv mkcert /usr/local/bin/
    popd
  fi
}

function install_kubectl() {
  # shellcheck disable=SC2076
  if ! check_cmd kubectl || [[ "$(kubectl version --client)" =~ "$KUBE_VERSION" ]]; then
    pushd /tmp
    # shellcheck disable=SC2086
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl" &&
      chmod +x kubectl &&
      mv kubectl /usr/local/bin/
    popd
  fi
}
