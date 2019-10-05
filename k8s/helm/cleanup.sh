#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

SKUBA_TF_DIR=${SKUBA_TF_DIR:-~/github/caasp/skuba/ci/infra/openstack}
KUBECONFIG=${KUBECONFIG:~/.kube/config}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}

function cleanup() {
  :
}

cleanup