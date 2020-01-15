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

function error() {
  if [[ $# -gt 0 ]]; then
    echo "$*" >>/dev/stderr
  fi

  exit 1
}

function k8s_version() {
  curl -sSfL "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
}

function git_release_version() {
  # ex: https://github.com/vmware-tanzu/velero/releases/latest
  value=$(curl -sSfL -H "Accept: application/json" "https://github.com/$1/releases/latest" | jq -r ".tag_name")
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

function zypper_pkg_install() {
  for i in "$@"; do
    zypper_cmd=in
    if check_cmd "$i"; then
      zypper_cmd=up
    fi

    # shellcheck disable=SC2086
    sudo zypper $zypper_cmd $ZYPPER_INSTALL_OPTS $i
  done
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
  pkgs=(sudo git curl tar gzip zip unzip which jq)
  zypper_pkg_install "${pkgs[@]}"

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
