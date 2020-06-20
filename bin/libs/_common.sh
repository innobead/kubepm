#!/usr/bin/env bash

set -o errexit

KU_SKIP_SETUP=${KU_SKIP_SETUP:-true}
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
  value=$(curl -sSfL "https://api.github.com/repos/$1/releases/latest" | jq -r ".tag_name")
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
 ./bin/install.sh init

 ./bin/install.sh all
 ./bin/$f <package name>
EOF
  for i in "$@"; do
    printf "  - %s\n" "$i"
  done
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
      error "Invalid install option ($1)"
    fi

    shift
  done

  echo "${installers[@]}"
}

function install_pkgs() {
  set -o xtrace

  for i in "${@}"; do
    run_sanbox "install_$i"
  done
}

function install_github_pkg() {
  local repo_path=${repo_path:-}
  local version=${version:-}
  local download_url=${download_url:-}
  local exec_name=${exec_name:-}
  local exec_version_cmd=${exec_version_cmd:-version}
  local install_cmd=${install_cmd:-}
  local is_github_pkg=${is_github_pkg:-true}
  local dest_dir=${dest_dir:-$KU_INSTALL_BIN}

  declare -a exec_names
  mapfile -t exec_names < <(echo "${exec_name//,/$'\n'}")
  local exec_name=${exec_names[0]}

  # for github pkg, validate the missing parameters and prepare some variables
  if [[ $is_github_pkg == "true" ]]; then
    if [[ -z $repo_path ]]; then
      error "No repo_path specified"
    fi

    if [[ -z "$version" ]]; then
      # get version and remove 'v' if the version has 'v' as a starting character
      version=$(git_release_version "$repo_path")
      if [[ "${version:0:1}" == "v" ]]; then
        version="${version:1}"
      fi
    fi

    if [[ -n $exec_name ]]; then
      # check if already have the latest version
      # shellcheck disable=SC2086
      if check_cmd "$exec_name" && [[ "$(eval "$exec_name $exec_version_cmd 2>&1")" =~ $version ]]; then
        return 0
      fi
    fi
  fi

  # download_url is mandatory
  if [[ -z "$download_url" ]]; then
    error "No download_url specified"
  fi

  local download_url="${download_url//\{VERSION\}/$version}"
  declare -a download_urls
  mapfile -t download_urls < <(echo "${download_url//,/$'\n'}")

  # process the download urls
  echo ">>>  ${download_urls[*]}"
  for index in "${!download_urls[@]}"; do
    download_url=${download_urls[index]}

    declare -a new_exec_names
    if [[ "${#download_urls[@]}" == "${#exec_names[@]}" ]]; then
      mapfile -t new_exec_names < <(echo "${exec_name//,/$'\n'}")
    else
      new_exec_names+=("${exec_names[@]}")
    fi

    download_url="https://github.com/$repo_path/releases/download/$download_url"

    # validate artifact file type
    case $download_url in
    *.tar.gz | *.tgz | *.zip | *.sh | *-amd64 | *-linux-x86_64) ;;
    *) error "Only tar.gz, zip supported" ;;
    esac

    # download the artifact and extract to the destination folder
    download_file=$(basename "$download_url")
    rm -rf "$download_file"
    curl -sSfLO "$download_url"

    local extract_dir=""

    case $download_url in
    *.tar.gz)
      extract_dir=${download_file%%.tar.gz}
      extract_cmd="tar -C $extract_dir --strip-components=1 -xzf $download_file"
      ;;
    *.tgz)
      extract_dir=${download_file%%.tgz}
      extract_cmd="tar -C $extract_dir --strip-components=1 -xzf $download_file"
      ;;
    *.zip)
      extract_dir=${download_file%%.zip}
      extract_cmd="unzip $download_file -d $extract_dir"
      ;;
    esac

    # extract the download file
    if [[ -n "$extract_dir" ]]; then
      # delete the previous cache w/o errors
      rm -rf "$extract_dir" || true
      mkdir "$extract_dir"
      $extract_cmd
    fi

    (sudo mkdir -p "$dest_dir" && sudo chown -R "$KU_USER" "$dest_dir") || true

    if [[ ${#new_exec_names[@]} -eq 0 ]]; then
      sudo cp "$extract_dir"/* "$dest_dir"/

    elif [[ -n "$install_cmd" ]]; then
      f=$(find "$extract_dir" -name "$install_cmd" | tr -d '\n')

      if [[ -n "$f" ]]; then
        sudo ./"$f"
      else
        cd "$extract_dir" && sudo $install_cmd && cd -
      fi

    else
      for exec_name in "${new_exec_names[@]}"; do
        # install executables into destination folder
        if [[ $download_file == *.sh ]]; then
          chmod +x "$download_file"
          sudo ./"$download_file"

        elif [[ $download_file =~ .*-amd64$ ]] || [[ $download_file =~ .*-linux-x86_64$ ]]; then
          if [[ ! $download_file =~ ^$exec_name.* ]]; then
            error "The name of downloaded file ($download_file) does not start with $exec_name"
          fi

          chmod +x "$download_file" && mv "$download_file" "$exec_name"
          sudo install "$exec_name" "$dest_dir"

        elif [[ -z "$install_cmd" ]]; then
          f=$(find "$extract_dir" -name "$exec_name" | tr -d '\n')
          sudo install "$f" "$dest_dir"

        fi

      done
    fi

    rm -rf "$extract_dir" "$download_file"

  done
}

function get_install_functions() {
  declare -a fns
  mapfile -t fns < <(declare -F | awk '{print $3}')

  for fn in "${fns[@]}"; do
    if [[ $fn =~ ^install_* ]] && [[ $fn != "install_pkgs" ]] && [[ $fn != "install_github_pkg" ]]; then
      fn=${fn#install_}
      echo "$fn"
    fi
  done
}

function run_sanbox() {
  pushd "${KU_TMP_DIR}"
  $1
  popd
}
