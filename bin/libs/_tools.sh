#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Constants
REG_VERSION=${REG_VERSION:-}
TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.11.14}
CFSSL_VERSION=${CFSSL_VERSION:-}

function install_terraform() {
  # shellcheck disable=SC2076
  if ! check_cmd terraform || [[ ! "$(terraform version)" =~ "$TERRAFORM_VERSION" ]]; then
    pushd /tmp
    curl -LO "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip terraform*.zip && rm terraform*.zip
    chmod +x terraform && sudo mv terraform /usr/local/bin
    popd
  fi

  if ! check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt; then
    pushd /tmp
    curl -LO "https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.2/terraform-provider-libvirt-0.5.2.openSUSE_Leap_15.1.x86_64.tar.gz"
    tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz
    mkdir -p ~/.terraform.d/plugins
    mv terraform-provider-libvirt ~/.terraform.d/plugins
    popd
  fi
}

function install_oci_tools() {
  sudo zypper in $ZYPPER_INSTALL_OPTS podman skopeo umoci helm-mirror

  if [[ -z $REG_VERSION ]]; then
    REG_VERSION=$(git_release_version genuinetools/reg)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd reg || [[ ! "$(reg version)" =~ "$REG_VERSION" ]]; then
    pushd /tmp
    curl -fL "https://github.com/genuinetools/reg/releases/download/$REG_VERSION/reg-freebsd-amd64" -o "/usr/local/bin/reg"
    chmod a+x "/usr/local/bin/reg"
    popd
  fi
}

function install_salt() {
  pushd /tmp
  curl -L "https://bootstrap.saltstack.com" -o bootstrap-salt.sh
  sudo bootstrap-salt.sh
  popd
}

function install_cert_tools() {
  if [[ -z $CFSSL_VERSION ]]; then
    CFSSL_VERSION=$(git_release_version cloudflare/cfssl)
  fi

  if ! check_cmd cfssl || [[ ! "$(cfssl vesion)" =~ ${CFSSL_VERSION:1} ]]; then
    files=(cfssl-bundle cfssl-certinfo cfssl-newkey cfssl-scan cfssljson cfssl mkbundle multirootca)

    for f in "${files[@]}"; do
      curl -sSL "https://github.com/cloudflare/cfssl/releases/download/$CFSSL_VERSION/${f}_${CFSSL_VERSION:1}_linux_amd64" -o "/usr/local/bin/$f"
    done
  fi
}
