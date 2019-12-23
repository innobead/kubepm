#!/usr/bin/env bash
# https://rook.github.io/docs/rook/master/ceph-quickstart.html#deploy-the-rook-operator

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

git clone --single-branch --branch master https://github.com/rook/rook.git
# shellcheck disable=SC2164
cd rook/cluster/examples/kubernetes/ceph

kubectl create -f common.yaml
kubectl create -f operator.yaml
kubectl create -f cluster-test.yaml
kubectl create -f toolbox.yaml
