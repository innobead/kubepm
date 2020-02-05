#!/usr/bin/env bash

# Import libs
CRT_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${CRT_DIR}"/../bin/libs/_common.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

if [[ "$#" == "0" ]]; then
  error "Please use a virsh command for the operation you like like resume, suspend, etc by \`virsh help\`".
fi

FILTER=${FILTER:-testing}
command=$1; shift

for vm in $(virsh list --all | grep "$FILTER" | awk '{print $2}'); do
  # shellcheck disable=SC2086
  # shellcheck disable=SC2068
  virsh $command $vm $@
done
