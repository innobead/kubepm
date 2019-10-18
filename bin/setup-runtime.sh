#!/usr/bin/env bash

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_runtime.sh

install_docker
install_libvirt
install_virtualbox
install_vagrant
