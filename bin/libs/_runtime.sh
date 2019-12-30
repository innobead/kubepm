#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

function install_docker() {
  if [[ -z $DOCKER_VERSION ]]; then
    DOCKER_VERSION=$(zypper_pkg_version docker)
  fi

  if ! check_cmd docker; then
    sudo zypper in $ZYPPER_INSTALL_OPTS docker
  elif [[ ! "$(docker version -f '{{.Server.Version}}')" =~ $DOCKER_VERSION ]]; then
    sudo zypper up $ZYPPER_INSTALL_OPTS docker
  fi

  sudo pip install --upgrade docker-compose
}

function install_libvirt() {
  if [[ -z $LIBVERT_VERSION ]]; then
    LIBVERT_VERSION=$(zypper_pkg_version libvirt)
  fi

  if ! check_cmd virsh; then
    sudo zypper in $ZYPPER_INSTALL_OPTS -t pattern kvm_server kvm_tools
  elif [[ ! "$(virsh version | grep libvirt | sed -n '1p' | awk '{print $5}')" =~ $LIBVERT_VERSION ]]; then
    sudo zypper up $ZYPPER_INSTALL_OPTS -t pattern kvm_server kvm_tools
  fi
}

function install_virtualbox() {
  if ! check_cmd virtualbox; then
    sudo zypper in $ZYPPER_INSTALL_OPTS virtualbox
  else
    sudo zypper up $ZYPPER_INSTALL_OPTS virtualbox
  fi
}

# https://github.com/vagrant-libvirt/vagrant-libvirt#installation
function install_vagrant() {
  sudo zypper in $ZYPPER_INSTALL_OPTS vagrant qemu libvirt libvirt-devel ruby-devel gcc qemu-kvm
  vagrant plugin install vagrant-libvirt
}
