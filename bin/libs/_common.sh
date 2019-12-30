#!/usr/bin/env bash

set -o errexit

FORCE_INSTALL=${FORCE_INSTALL:-}
ZYPPER_INSTALL_OPTS=${ZYPPER_INSTALL_OPTS:--y -l}
USER=$(id -un)

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

function git_release_version() {
  # ex: https://github.com/vmware-tanzu/velero/releases/latest
  value=$(curl -sL -H "Accept: application/json" "https://github.com/$1/releases/latest" | jq -r ".tag_name")
  if [[ $value == "null" ]]; then
    echo ""
  else
    echo "$value"
  fi
}

function zypper_pkg_version() {
  value=$(zypper info "$1" | grep -i version | awk -F : '{print $2}' | tr -d ' ')
  if [[ $value == "null" ]]; then
    echo ""
  else
    echo "$value"
  fi
}

function add_repos() {
  sudo zypper ar "http://download.opensuse.org/tumbleweed/repo/oss/" opensuse_factory_oss || true
  sudo zypper ar "https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed" snappy || true
  sudo zypper --gpg-auto-import-keys ref
}

function remove_repos() {
  sudo zypper mr -d opensuse_factory_oss
  sudo zypper mr -d snappy
}

function in_container() {
  [[ -f "/run/containerenv" || -f "/.dockerenv" ]]
  return $?
}

function setup() {
  # Install the general packages from the same distribution instead of factory
  sudo zypper in -y sudo git curl tar gzip zip unzip which jq

  add_repos
}

function cleanup() {
  remove_repos
}

function signal_handle() {
  # shellcheck disable=SC2086
  trap $1 EXIT ERR INT TERM
}

# Setup, Teardown
signal_handle cleanup
setup
