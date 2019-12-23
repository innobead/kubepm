#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

git clone --single-branch --branch master https://github.com/kubernetes-incubator/external-storage.git || true
# shellcheck disable=SC2164
cd external-storage/nfs/deploy/kubernetes

for f in "deployment.yaml" "rbac.yaml" "class.yaml" "claim.yaml"; do
  kubectl delete -f "$f"
done
