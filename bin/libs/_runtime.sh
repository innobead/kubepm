#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

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
    qemu
    libvirt
    libvirt-devel
    ruby-devel
    gcc
    qemu-kvm
  )
  zypper_pkg_install "${pkgs[@]}"

  repo_path=hashicorp/vagrant \
    version="2.2.7" \
    download_url="https://releases.hashicorp.com/vagrant/{VERSION}/vagrant_{VERSION}_linux_amd64.zip" \
    exec_name=vagrant \
    exec_version_cmd="version" \
    install_github_pkg

  # v$(vagrant version | head -n 1 | awk '{print $3}')

  curl -sSfLO https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_linux_amd64.zip

  CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib" vagrant plugin install vagrant-libvirt
}
