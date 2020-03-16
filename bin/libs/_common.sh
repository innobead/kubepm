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
    error "Failed to get the latest version from github"
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

function install_github_pkg() {
  repo_path=${repo_path:-}
  version=${version:-}
  download_url=${download_url:-}
  exec_name=${exec_name:-}
  exec_version_cmd=${exec_version_cmd:-version}
  install_cmd=${install_cmd:-}
  is_github_pkg=${is_github_pkg:-true}

  if [[ -z "$download_url" ]]; then
    error "No download_url specified"
  fi
  download_url="https://github.com/$repo_path/releases/download/$download_url"

  if [[ $is_github_pkg == "true" ]]; then
    if [[ -z $repo_path ]] || [[ -z $exec_name ]]; then
      error "No repo_path, exec_name specified"
    fi

    if [[ -z "$version" ]]; then
      # get version and remove 'v' if the version has 'v' as a starting character
      version=$(git_release_version "$repo_path")
      if [[ "${version:0:1}" == "v" ]]; then
        version="${version:1}"
      fi
    fi

    # check if already have the latest version
    if check_cmd "$exec_name" && [[ "$($exec_name "$exec_version_cmd")" =~ $version ]]; then
      return 0
    fi
  fi

  download_url="${download_url//\{VERSION\}/$version}"

  # validate artifact file type
  case $download_url in
  *.tar.gz | *.tgz | *.zip | *.sh | *-linux-amd64) ;;
  *) error "Only tar.gz, zip supported" ;;
  esac

  pushd "$KU_TMP_DIR"

  # download the artifact and extract to the destination folder
  filename=$(basename "$download_url")
  rm -rf "$filename"
  curl -sSfLO "$download_url"

  case $download_url in
  *.tar.gz)
    extract_dir=${filename%%.tar.gz}
    cmd="tar -C $extract_dir -xzf $filename"
    ;;
  *.tgz)
    extract_dir=${filename%%.tgz}
    cmd="tar -C $extract_dir -xzf $filename"
    ;;
  *.zip)
    extract_dir=${filename%%.zip}
    cmd="unzip $filename -d $extract_dir"
    ;;
  esac

  if [[ -n "$extract_dir" ]]; then
    # delete the previsous cache w/o errors
    rm -rf "$extract_dir" || true
    mkdir "$extract_dir"
    $cmd
  fi

  if [[ $filename == *.sh ]]; then
    chmod +x "$filename"
    sudo ./"$filename"

  elif [[ $filename =~ .*-linux-amd64$ ]]; then
    if [[ ! $filename =~ ^$exec_name.* ]]; then
      error "The name of downloaded file ($filename) does not start with $exec_name"
    fi

    chmod +x "$filename" && mv "$filename" "$exec_name"
    sudo install "$exec_name" "$KU_INSTALL_BIN"

  elif [[ -z "$install_cmd" ]]; then
    f=$(find "$extract_dir" -name "$exec_name" | tr -d '\n')
    sudo install "$f" "$KU_INSTALL_BIN"

  else
    f=$(find "$extract_dir" -name "$install_cmd" | tr -d '\n')
    sudo ./"$f"

  fi

  rm -rf "$extract_dir" "$filename"

  popd
}
