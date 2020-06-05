#!/usr/bin/env bash

BIN_DIR=$(dirname "$(realpath "$0")")

# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_dev.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_k8s.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_runtime.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_container.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_tools.sh
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_suse.sh

set -o errexit
set -o pipefail

declare -a builtin_installers
mapfile -t builtin_installers < <(get_install_functions)
declare -a installers

case "$1" in
help | "")
  help "${builtin_installers[@]}"
  exit 0
  ;;
init) # this is an hidden command for initializing necessary artifacts in the container image
  init
  cleanup
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
