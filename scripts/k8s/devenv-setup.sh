#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

function install_kind() {
  curl -L https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-linux-amd64 -o kind &&
    chmod +x kind &&
    mv kind /usr/local/bin/
}

install_kind
