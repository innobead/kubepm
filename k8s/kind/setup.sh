#!/usr/bin/env bash
# https://rook.github.io/docs/rook/master/ceph-quickstart.html#deploy-the-rook-operator

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

kubectl create -f mutliple_nodes_cluster.yaml
