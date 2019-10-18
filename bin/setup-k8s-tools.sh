#!/usr/bin/env bash

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_k8s_tools.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

install_kind
install_minikube
install_helm
install_kubectl
install_mkcert
