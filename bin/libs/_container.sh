#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

function install_docker() {
  zypper_cmd=in
  if check_cmd docker; then
    zypper_cmd=up
  fi

  # shellcheck disable=SC2086
  sudo zypper $zypper_cmd $KU_ZYPPER_INSTALL_OPTS docker

  sudo pip install --upgrade docker-compose
}

function install_lxc() {
  cmd=install
  if check_cmd lxd; then
    cmd=refresh
  fi
  sudo snap "$cmd" --classic lxd

  sudo usermod -a -G lxd "${KU_USER}"
  sudo systemctl start snap.lxd.daemon.service
  sudo systemctl enable snap.lxd.daemon.service

  # when running `lxc list image images:` and encoutering a url unresolved issue, please reload snap.lxd.deamon. It's because network ready after snap for some reason.
  # sudo systemctl reload snap.lxd.daemon

  cat <<EOF
Use $(lxc help) to learn how to manage container and images.

lxc init: Please relogin to take effect all installation, then execute below commands.

  cat >lxd.yaml <<\EOF
config: {}
networks:
- config:
    ipv4.address: 172.22.0.1/16
    ipv4.nat: "true"
    ipv6.address: auto
  description: ""
  managed: false
  name: lxdbr0
  type: ""
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
\EOF

  cat lxd.yaml | lxd init --preseed - && rm lxd.yaml

Commands:
  lxc list image images:
  lxc launch images:opensuse/tumbleweed/amd64 opensuse
  lxc exec opensuse -- passwd root
  lxc config set opensuse limits.memory 1GB
  lxc exec opensuse -- free -h
  lxc delete opensuse --force
EOF
}

function install_podman() {
  # shellcheck disable=SC2086
  if ! check_cmd podman; then
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS podman
  else
    sudo zypper up $KU_ZYPPER_INSTALL_OPTS podman
  fi

  if ! in_container; then
    sudo systemctl enable snapd
    sudo systemctl start snapd
  fi
}

function install_crio() {
  :
}

function install_containerd() {
    :
}
