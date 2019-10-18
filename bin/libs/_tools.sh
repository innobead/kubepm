#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Constants
REG_VERSION=${REG_VERSION:-v0.16.0}
TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.11.11}

function install_terraform() {
  if ! check_cmd terraform; then
    pushd /tmp
    curl -LO "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip terraform*.zip && rm terraform*.zip
    chmod +x terraform && sudo mv terraform /usr/local/bin
    popd
  fi

  if ! check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt; then
    pushd /tmp
    curl -LO "https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.1/terraform-provider-libvirt-0.5.1.openSUSE_Leap_15.0.x86_64.tar.gz"
    tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz
    popd

    mkdir -p ~/.terraform.d/plugins
    mv terraform-provider-libvirt ~/.terraform.d/plugins
  fi
}

function install_ocitools() {
  sudo zypper in $ZYPPER_INSTALL_OPTS podman skopeo helm-mirror

  pushd /tmp
  curl -fL "https://github.com/genuinetools/reg/releases/download/$REG_VERSION/reg-freebsd-amd64" -o "/usr/local/bin/reg" &&
    chmod a+x "/usr/local/bin/reg"
  popd
}

function install_salt() {
  pushd /tmp
  curl -L "https://bootstrap.saltstack.com" -o bootstrap-salt.sh
  sudo bootstrap-salt.sh
  popd
}
