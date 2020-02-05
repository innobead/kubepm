#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

function add_repos() {
  sudo zypper ar "http://download.opensuse.org/tumbleweed/repo/oss/" opensuse_factory_oss || true
  sudo zypper ar "https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed" snappy || true
  sudo zypper --gpg-auto-import-keys ref
}

function remove_repos() {
  sudo zypper mr -d opensuse_factory_oss
  sudo zypper mr -d snappy
}

function setup() {
  # Install the general packages from the same distribution instead of factory
  pkgs=(sudo git curl tar gzip zip unzip which jq)
  zypper_pkg_install "${pkgs[@]}"

  add_repos
}

function cleanup() {
  remove_repos
}

# Setup, Teardown
signal_handle cleanup
setup
