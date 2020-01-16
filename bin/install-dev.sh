#!/usr/bin/env bash

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_dev.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

builtin_installers=(
  sdkman
  bazel
  snap
  gofish
  go
  gradle
  python
  ruby
  rust
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
