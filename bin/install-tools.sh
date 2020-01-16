#!/usr/bin/env bash

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_tools.sh

builtin_installers=(
  terraform
  oci_tools
  salt
  cert_tools
  ldap_tools
)

declare -a installers
if [[ "$#" == "0" ]]; then
  installers+=("${builtin_installers[@]}")
fi

while (($#)); do
  # shellcheck disable=SC2076
  # shellcheck disable=SC2199
  if [[ "${builtin_installers[@]}" =~ "$1" ]]; then
    installers+=("${installers[@]}" "$1")
  else
    echo "Invalid install option ($1)"
  fi

  shift
done

for i in "${installers[@]}"; do
  $"install_$i"
done