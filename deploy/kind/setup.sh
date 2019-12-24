#!/usr/bin/env bash
# https://rook.github.io/docs/rook/master/ceph-quickstart.html#deploy-the-rook-operator

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_common.sh
# shellcheck disable=SC2164
cd "$DIR"

kind create cluster --name mc --config="$(pwd)/manifests/mutliple-nodes-cluster.yaml"
