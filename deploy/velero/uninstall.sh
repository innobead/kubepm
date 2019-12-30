#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

pids=$(set +o pipefail && pgrep -f "kubectl -n velero port-forward" | tr "\n" " ")
if [[ -n $pids ]]; then
  for pid in $pids; do
    # shellcheck disable=SC2086
    kill -9 $pid
  done
fi

kubectl delete -f manifests
kubectl delete -f manifests/nginx-app/with-pv.yaml
kubectl delete clusterrolebinding/velero
kubectl delete crds -l component=velero
