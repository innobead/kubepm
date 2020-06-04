#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_common.sh

function add_repos() {
  #  sudo zypper ar "http://download.opensuse.org/tumbleweed/repo/oss/" opensuse_factory_oss || true
  #  sudo zypper --gpg-auto-import-keys ref opensuse_factory_oss
  :
}

function remove_repos() {
  :
  #  sudo zypper rr opensuse_factory_oss snappy 2>/dev/null || true
}

function setup() {
  remove_repos

  # Install the general packages from the same distribution instead of factory
  pkgs=(sudo git curl tar gzip zip unzip which jq)
  zypper_pkg_install "${pkgs[@]}"

  if [[ $KU_SKIP_SETUP != "true" ]]; then
    add_repos
  fi
}

function cleanup() {
  if [[ $KU_SKIP_SETUP != "true" ]]; then
    remove_repos
  fi
}

# Setup, Teardown
signal_handle cleanup
setup
