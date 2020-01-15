#!/usr/bin/env bash

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_dev.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

# Constants
function install_execs() {
  sudo zypper in -y \
    go-md2man \
    git \
    pkgconfig \
    runc
}

function install_libs() {
  sudo zypper in -y \
    libcontainers-common \
    device-mapper-devel \
    glib2-devel \
    glibc-devel \
    glibc-static \
    gpgme-devel \
    libassuan-devel \
    libgpg-error-devel \
    libseccomp-devel \
    libselinux-devel \
    libbtrfs-devel
}

echo "Note: installation is based on https://github.com/cri-o/cri-o/blob/master/tutorials/setup.md"

install_go
install_execs
install_libs
