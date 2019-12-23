#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

function install_docker() {
  if ! check_cmd docker; then
    sudo zypper in $ZYPPER_INSTALL_OPTS docker
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

# https://github.com/vagrant-libvirt/vagrant-libvirt#installation
function install_vagrant() {
  zypper in $ZYPPER_INSTALL_OPTS vagrant qemu libvirt libvirt-devel ruby-devel gcc qemu-kvm
  vagrant plugin install vagrant-libvirt
}
