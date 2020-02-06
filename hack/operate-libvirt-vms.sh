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
  error "Please use a virsh command for the operation you like like resume, suspend, etc by \`virsh help\`." \
    "There is a special command \`clean\` to destroy & undefine resources together."
fi

FILTER=${FILTER:-testing}
command=$1
shift

for vm in $(virsh list --all | grep "$FILTER" | awk '{print $2}'); do
  # shellcheck disable=SC2086
  # shellcheck disable=SC2068
  if [[ $command == "clean" ]]; then
    virsh destroy $vm
    vrish undefine $vm
  else
    virsh $command $vm $@
  fi
done

if [[ $command == "clean" ]]; then
  for vol in $(virsh vol-list --pool default | grep "$FILTER" | awk '{print $2}'); do
    # shellcheck disable=SC2086
    virsh vol-delete --pool default $vol
  done

  for net in $(virsh net-list --all | grep "$FILTER" | awk '{print $1}'); do
    # shellcheck disable=SC2086
    virsh net-destroy $net
  done

  for net in $(virsh net-list --all | grep "$FILTER" | awk '{print $1}'); do
    # shellcheck disable=SC2086
    virsh net-undefine $net
  done
fi
