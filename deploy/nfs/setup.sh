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

git clone --single-branch --branch master https://github.com/kubernetes-incubator/external-storage.git || true

# shellcheck disable=SC2164
pushd external-storage/nfs/deploy/kubernetes
for f in "deployment.yaml" "rbac.yaml" "class.yaml" "claim.yaml"; do
  #  sed -i -E "s/namespace: .*/namespace: $NAMESPACE/g" $f
  kubectl create -f "$f"
done
popd

kubectl patch service nfs-provisioner --type merge --patch "$(cat patch.yaml)"
