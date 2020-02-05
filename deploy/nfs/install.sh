#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_init.sh
# shellcheck disable=SC2164
cd "$DIR"

helm install nfs-server-provisioner stable/nfs-server-provisioner
