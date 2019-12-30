#!/usr/bin/env bash
# https://velero.io/docs/v1.2.0/contributions/minio/

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

helm repo add rimusz https://charts.rimusz.net
helm install hostpath-provisioner rimusz/hostpath-provisioner --version 0.2.6
