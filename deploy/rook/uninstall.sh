#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

git clone --single-branch --branch master https://github.com/rook/rook.git
# shellcheck disable=SC2164
pushd rook/cluster/examples/kubernetes/ceph
for f in "common.yaml" "operator.yaml" "cluster-test.yaml" "toolbox.yaml"; do
  #  sed -i -E "s/namespace: .*/namespace: $NAMESPACE/g" $f
  kubectl delete -f "$f"
done
popd

helm uninstall ceph-csi-rbd -n ceph-csi
helm uninstall ceph-csi-rbd -n ceph-csi
kubectl delete ns ceph-csi
