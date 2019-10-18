#!/usr/bin/env bash

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_dev.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

install_sdkman
install_snap
install_gofish
install_go
install_gradle
install_python
install_ruby
