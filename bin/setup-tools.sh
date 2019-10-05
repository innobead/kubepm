#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Setup, Teardown
common_setup
trap common_cleanup EXIT ERR INT TERM

# Constants
REG_VERSION=v0.16.0
TERRAFORM_VERSION=0.11.11

function install_terraform() {
  if ! check_cmd terraform; then
    curl -LO "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip terraform*.zip && rm terraform*.zip
    chmod +x terraform && sudo mv terraform /usr/local/bin
  fi

  if ! check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt; then
    curl -LO "https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.1/terraform-provider-libvirt-0.5.1.openSUSE_Leap_15.0.x86_64.tar.gz"
    tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz

    mkdir -p ~/.terraform.d/plugins
    mv terraform-provider-libvirt ~/.terraform.d/plugins
  fi
}

function install_docker() {
  if ! check_cmd docker; then
    sudo zypper ar --refresh opensuse_factory_oss http://download.opensuse.org/tumbleweed/repo/oss/
    sudo zypper install -y docker
    sudo zypper mr -d opensuse_factory_oss
  fi

  if ! check_cmd docker-compose; then
    sudo pip install docker-compose
  fi
}

function install_libvirt() {
  if ! check_cmd virsh; then
    sudo zypper install -y -t pattern kvm_server kvm_tools
  fi
}

function install_ocitools() {
  sudo zypper in -y podman skopeo helm-mirror

  curl -fL "https://github.com/genuinetools/reg/releases/download/$REG_VERSION/reg-freebsd-amd64" -o "/usr/local/bin/reg" &&
    chmod a+x "/usr/local/bin/reg"
}

install_terraform
install_docker
install_libvirt
install_ocitools
