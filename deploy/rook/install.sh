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

git clone --single-branch --branch master https://github.com/rook/rook.git
# shellcheck disable=SC2164
pushd rook/cluster/examples/kubernetes/ceph
for f in "common.yaml" "operator.yaml" "cluster-test.yaml" "toolbox.yaml"; do
  #  sed -i -E "s/namespace: .*/namespace: $NAMESPACE/g" $f
  kubectl create -f "$f"
done
popd

helm repo add ceph-csi https://ceph.github.io/csi-charts

kubectl create ns ceph-csi
helm install ceph-csi-rbd ceph-csi/ceph-csi-rbd -n ceph-csi
helm install ceph-csi-rbd ceph-csi/ceph-csi-cephfs -n ceph-csi