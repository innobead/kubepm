#!/usr/bin/env bash

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

function install_docker() {
  if ! check_cmd docker; then
    sudo zypper ar --refresh opensuse_factory_oss http://download.opensuse.org/tumbleweed/repo/oss/
    sudo zypper in $ZYPPER_INSTALL_OPTS docker
    sudo zypper mr -d opensuse_factory_oss
  fi

  if ! check_cmd docker-compose; then
    sudo pip install docker-compose
  fi
}

function install_libvirt() {
  if ! check_cmd virsh; then
    sudo zypper in $ZYPPER_INSTALL_OPTS -t pattern kvm_server kvm_tools
  fi
}

function install_virtualbox() {
    zypper in $ZYPPER_INSTALL_OPTS virtualbox
}

function install_vagrant() {
    zypper in $ZYPPER_INSTALL_OPTS vagrant
}

install_docker
install_libvirt
install_virtualbox
install_vagrant
