#!/usr/bin/env bash

set -o errexit

KU_SKIP_SETUP=${KU_SKIP_SETUP:-false}
KU_FORCE_INSTALL=${KU_FORCE_INSTALL:-false}
KU_ZYPPER_INSTALL_OPTS=${KU_ZYPPER_INSTALL_OPTS:--y -l}
KU_USER=$(id -un)
KU_INSTALL_DIR=${KU_INSTALL_DIR:-/usr/local/lib}
KU_INSTALL_BIN=${KU_INSTALL_BIN:-/usr/local/bin}
KU_TMP_DIR=${KU_TMP_DIR:-/tmp}

function check_cmd() {
  if [[ $KU_FORCE_INSTALL != "false" ]]; then
    return 1
  fi

  command -v "$1" 2>/dev/null
  return $?
}

function error() {
  if [[ $# -gt 0 ]]; then
    echo "$*" >>/dev/stderr
  fi

  exit 1
}

function k8s_version() {
  curl -sSfL "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
}

function git_release_version() {
  # ex: https://github.com/vmware-tanzu/velero/releases/latest
  value=$(curl -sSfL -H "Accept: application/json" "https://github.com/$1/releases/latest" | jq -r ".tag_name")
  if [[ $value == "null" ]]; then
    echo ""
  else
    echo "$value"
  fi
}

function zypper_pkg_version() {
  value=$(zypper info "$1" | grep -i version | awk -F : '{print $2}' | tr -d ' ')
  if [[ $value == "null" ]]; then
    echo ""
  else
    echo "$value"
  fi
}

function zypper_pkg_install() {
  for i in "$@"; do
    zypper_cmd=in
    if check_cmd "$i"; then
      zypper_cmd=up
    fi

    # shellcheck disable=SC2086
    sudo zypper $zypper_cmd $KU_ZYPPER_INSTALL_OPTS $i
  done
}

function in_container() {
  [[ -f "/run/containerenv" || -f "/.dockerenv" ]]
  return $?
}

function signal_handle() {
  # shellcheck disable=SC2086
  trap $1 EXIT ERR INT TERM
}

function help() {
  f=$(basename "$(realpath "$0")")

  vars=$(
    set -o posix
    set |
      grep "KU_" |
      sort |
      awk '{printf " %s\n", $0}'
  )
  cat <<EOF
Configurable Variables:
$vars

Command Usage:
  ./bin/$f [$(printf " %s |" "${@}") all ]
EOF
}

function collect_pkgs() {
  # shellcheck disable=SC2001
  mapfile -t builtin_installers < <(echo "$1" | sed 's/\s/\n/g')
  # shellcheck disable=SC2001
  mapfile -t want_installers < <(echo "$2" | sed 's/\s/\n/g')

  set -- "${want_installers[@]}"
  declare -a installers

  while (($#)); do
    # shellcheck disable=SC2076
    # shellcheck disable=SC2199
    if [[ "${builtin_installers[@]}" =~ "$1" ]]; then
      installers+=("$1")
    else
      echo "Invalid install option ($1)"
    fi

    shift
  done

  echo "${installers[@]}"
}

function install_pkgs() {
  set -o xtrace

  for i in "${@}"; do
    $"install_$i"
  done
}
