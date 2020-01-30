#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_common.sh
# shellcheck disable=SC2164
cd "$DIR"


./uninstall.sh || true
HELM_VERSION=v2.16.1 ./../../bin/install-k8s-tools.sh helm

kubectl create -f manifests
helm2 init --service-account tiller
