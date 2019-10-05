#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

function check_cmd() {
    command -v "$1" 2>/dev/null
    return $?
}

function k8s_version() {
    curl -sL "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
}

function add_tumbleweed_repos() {
  sudo zypper ar --refresh opensuse_factory_oss http://download.opensuse.org/tumbleweed/repo/oss/
}

function remove_tumbleweed_repos() {
  sudo zypper mr -d opensuse_factory_oss
}

function common_setup() {
    add_tumbleweed_repos
}

function common_cleanup() {
    remove_tumbleweed_repos
}