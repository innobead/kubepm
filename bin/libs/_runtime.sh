#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_init.sh

function install_docker() {
  zypper_cmd=in
  if check_cmd docker; then
    zypper_cmd=up
  fi
  sudo zypper $zypper_cmd $ZYPPER_INSTALL_OPTS docker

  sudo pip install --upgrade docker-compose
}

function install_libvirt() {
  zypper_cmd=in
  if check_cmd virsh; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd $ZYPPER_INSTALL_OPTS -t pattern kvm_server kvm_tools
}

function install_virtualbox() {
  zypper_cmd=in
  if check_cmd virtualbox; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd $ZYPPER_INSTALL_OPTS virtualbox
}

# https://github.com/vagrant-libvirt/vagrant-libvirt#installation
function install_vagrant() {
  pkgs=(
    vagrant
    qemu
    libvirt
    libvirt-devel
    ruby-devel
    gcc
    qemu-kvm
  )
  zypper_pkg_install "${pkgs[@]}"

  vagrant plugin install vagrant-libvirt
}
