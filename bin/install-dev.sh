#!/usr/bin/env bash

BIN_DIR=$(dirname "$(realpath "$0")")

# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

set -o errexit
#set -o nounset
set -o pipefail

builtin_installers=(
  sdkman
  bazel
  snap
  gofish
  go
  go_dev_tools
  gradle
  python
  ruby
  rust
  protobuf
  jwt
  hub
  bcrypt
)
declare -a installers

case "$1" in
help | "")
  help "${builtin_installers[@]}"
  exit 0
  ;;
all)
  installers+=("${builtin_installers[@]}")
  ;;
*)
  mapfile -t installers < <(collect_pkgs "${builtin_installers[*]}" "${*}" | sed 's/\s/\n/g')
  ;;
esac

# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_dev.sh

install_pkgs "${installers[@]}"
