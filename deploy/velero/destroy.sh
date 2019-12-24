#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

kubectl delete -f manifests
kubectl delete -f manifests/nginx-app/with-pv.yaml
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
