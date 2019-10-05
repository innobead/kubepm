#!/usr/bin/env bash

FORCE_INSTALL=${FORCE_INSTALL:-}
ZYPPER_INSTALL_OPTS=${ZYPPER_INSTALL_OPTS:--y -l}

function check_cmd() {
  if [[ -n $FORCE_INSTALL ]]; then
    return 1
  fi

  command -v "$1" 2>/dev/null
  return $?
}

function k8s_version() {
  curl -sL "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
}

function add_tumbleweed_repos() {
  sudo zypper ar --refresh "http://download.opensuse.org/tumbleweed/repo/oss/" opensuse_factory_oss
  sudo zypper ar --refresh "https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed" snappy
}

function remove_tumbleweed_repos() {
  sudo zypper mr -d opensuse_factory_oss
  sudo zypper mr -d snappy
}

function common_setup() {
  zypper in -y sudo git curl tar gzip zip unzip which

  add_tumbleweed_repos
}

function common_cleanup() {
  remove_tumbleweed_repos
}

# Setup, Teardown
common_setup
trap common_cleanup EXIT ERR INT TERM