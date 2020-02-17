#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

function install_docker() {
  zypper_cmd=in
  if check_cmd docker; then
    zypper_cmd=up
  fi
  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" docker

  sudo pip install --upgrade docker-compose
}

function install_libvirt() {
  zypper_cmd=in
  if check_cmd virsh; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" -t pattern kvm_server kvm_tools

  virt-host-validate qemu
}

function install_virtualbox() {
  zypper_cmd=in
  if check_cmd virtualbox; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" virtualbox
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
