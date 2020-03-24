#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

function install_suse_caasp_env() {
  # install terraform-provider-susepubliccloud
  r=http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40:/Update/standard/

  sudo zypper rr $r || true
  sudo zypper ar $r terraform-provider-susepubliccloud
  sudo zypper in --repo=$r terraform-provider-susepubliccloud
  sudo zypper rr $r
}

function install_suse_sles_images() {
  pushd "${KU_TMP_DIR}"
  curl -sSfLO https://download.suse.de/install/SLE-15-SP1-JeOS-QU2/SLES15-SP1-JeOS.x86_64-15.1-OpenStack-Cloud-QU2.qcow2
  sudo mv SLES15-SP1-JeOS.x86_64-15.1-OpenStack-Cloud-QU2.qcow2 /opt/images
  popd
}